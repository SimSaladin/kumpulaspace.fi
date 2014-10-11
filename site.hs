--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Control.Monad
import           Data.Maybe (fromMaybe)
import           Data.Monoid ((<>), mconcat)
import           Data.List (intercalate)
import           Data.Functor ((<$>))
import           Hakyll
import           Text.Pandoc.Options (ReaderOptions(..), WriterOptions(..))


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "templates/*" $ compile templateCompiler

    match "content/publications/*.pdf" $ do
        route $ gsubRoute "content/" (const "")
        compile $
            copyFileCompiler >>= saveSnapshot "pdfs"

    match "content/*/*.markdown" $ do
        route $ gsubRoute "content/" (const "") `composeRoutes`
                customRoute setLang `composeRoutes`
                setExtension "html"
        compile $ do
            ctx <- defaultContextWithLang
            getResourceBody
                >>= applyAsTemplate ctx
                >>= return . renderPandocWith myPandocReaderOpt myPandocWriterOpt
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    match "content/*.markdown" $ do
        route $ gsubRoute "content/" (const "") `composeRoutes`
                customRoute setLang `composeRoutes`
                setExtension "html"

        compile $ do
            defCtx       <- defaultContextWithLang
            lang         <- getLang
            projects     <- recentFirst =<< loadAll (fromGlob $ "content/projects/*-" ++ lang ++ ".*")
            publications <- liftM reverse $ loadAllSnapshots "content/publications/*" "pdfs" :: Compiler [Item CopyFile]
            let ctx =
                    listField "projects" projectCtx (return projects) <>
                    listField "publications" defaultContext (return $ map (fmap $ const "") publications) <>
                    defCtx
            getResourceBody
                >>= applyAsTemplate ctx
                >>= return . renderPandocWith myPandocReaderOpt myPandocWriterOpt
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    create [".htaccess"] $ do
        route idRoute
        compile $ makeItem ("Redirect 301 /test/index.html /test/en/" :: String)

--------------------------------------------------------------------------------

-- | Like defaultContext, but adds @lang@ field from filename.
defaultContextWithLang :: Compiler (Context String)
defaultContextWithLang = do
    lang <- getLang
    url  <- getUnderlying >>= liftM (fromMaybe "") . getRoute
    return $ constField "lang" lang
        <> languagesField "lang_choices" url lang
        <> navigationFieldsFor lang
        <> defaultContext

projectCtx :: Context String
projectCtx =
    dateField "date" "%B %e, %Y" <>
    defaultContext

-- Pandoc rendering

myPandocReaderOpt :: Text.Pandoc.Options.ReaderOptions
myPandocReaderOpt = defaultHakyllReaderOptions

myPandocWriterOpt :: WriterOptions
myPandocWriterOpt = defaultHakyllWriterOptions { writerSectionDivs = True }

-- Template language contexts

type Languages = [(String, String)]

availableLanguages :: Compiler Languages
availableLanguages = read <$> unsafeCompiler (readFile "languages.conf")

-- | @languagesField key currentUrl oldLang@
languagesField :: String -> String -> String -> Context a
languagesField k url oldLang = listField k
    (changeLanguageField url oldLang)
    (map (\(i, n) -> Item (fromFilePath i) n) <$> availableLanguages)

-- | Provides @$url$@ and @$title$@.
--
-- @changeLanguageField currentUrl oldLang@
changeLanguageField :: String -> String -> Context String
changeLanguageField url oldLang =
    field "url" (return . replaceLang . toFilePath . itemIdentifier) <>
    field "title" (return . itemBody)
    where
        replaceLang newLang =
            replaceAll ("/" ++ oldLang ++ "/") (const $ "/" ++ newLang ++ "/")
            $ toUrl url

-- | Get @lang@ from filename.
getLang :: Compiler String
getLang = takeWhile (/= '.') . last . splitAll "-" . toFilePath <$> getUnderlying

-- | 'file-fi.ext' to 'fi/file.ext'
setLang :: Identifier -> FilePath
setLang ident = let xs          = splitAll "-" $ toFilePath ident
                    (lang, ext) = span (/= '.') $ last xs
                    in lang ++ "/" ++ intercalate "-" (init xs) ++ ext

-- * Templates i18n

templateLanguages :: String -> Languages
templateLanguages lang = read <$> unsafeCompiler (readFile $ "templates-" ++ lang ++ ".conf")

-- | Navigation links i18n
navigationFieldsFor :: String -> Context String
navigationFieldsFor l = map (uncurry constField) $ case l of
    "en" -> enFields
    "fi" -> fiFields
    _    -> error ("Unknown language: " ++ l)

enFields =
    [ ("main_title", "Kumpula Space Centre")
    , ("nav_home", "Home")
    , ("nav_organisation", "Organisation")
    , ("nav_publications", "Publications")
    , ("nav_projects", "Projects")
    , ("nav_thesis_topics", "Topics for MSc Theses")
    ]

fiFields =
    [ ("main_title", "Kumpulan Avaruuskeskus")
    , ("nav_home", "Pääsivu")
    , ("nav_organisation", "Organisaatio")
    , ("nav_publications", "Julkaisut")
    , ("nav_projects", "Projektit")
    , ("nav_thesis_topics", "Pro gradu aiheita")
    ]
