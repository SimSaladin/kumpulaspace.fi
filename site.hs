--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid ((<>), mconcat)
import           Data.List (intercalate)
import           Data.Functor ((<$>))
import           Hakyll
import           Text.Pandoc.Options (WriterOptions(..))


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

    match "content/**.pdf" $ do
        route $ gsubRoute "content/" (const "")
        compile copyFileCompiler

    match (fromRegex "content/.*-(fi|en).(html|markdown|rst)") $ do
        route $ gsubRoute "content/" (const "") `composeRoutes`
                customRoute setLang `composeRoutes`
                setExtension "html"

        compile $ do
            defCtx       <- defaultContextWithLang
            lang         <- getLang
            projects     <- recentFirst =<< loadAll (fromGlob $ "content/projects/*-" ++ lang ++ ".*")
            publications <- loadAll (fromGlob "content/publications/*.pdf")
            let ctx =
                    listField "projects" projectCtx (return projects) <>
                    listField "publications" defaultContext (return publications) <>
                    defCtx
            getResourceBody
                >>= applyAsTemplate ctx
                >>= return . renderPandocWith myPandocReaderOpt myPandocWriterOpt
                >>= loadAndApplyTemplate "templates/default.html" ctx

    -- This index should never be served, but act as a notifier of
    -- misconfiguration.
    create ["index.html"] $ do
        route idRoute
        compile $ makeItem ("This index should be redirected to en/index.html!" :: String)

--------------------------------------------------------------------------------
projectCtx :: Context String
projectCtx =
    dateField "date" "%B %e, %Y" <>
    defaultContext

myPandocReaderOpt = defaultHakyllReaderOptions
myPandocWriterOpt = defaultHakyllWriterOptions { writerSectionDivs = True }

-- | 'file-fi.ext' to 'fi/file.ext'
setLang :: Identifier -> FilePath
setLang ident = let xs          = splitAll "-" $ toFilePath ident
                    (lang, ext) = span (/= '.') $ last xs
                    in lang ++ "/" ++ intercalate "-" (init xs) ++ ext

-- | defaultContext, but add "lang" field from filename.
defaultContextWithLang :: Compiler (Context String)
defaultContextWithLang = do
    lang <- getLang
    return $ constField "lang" lang
        <> navigationFieldsFor lang
        <> defaultContext

-- | Get lang from filename
getLang :: Compiler String
getLang = takeWhile (/= '.') . last . splitAll "-" . toFilePath <$> getUnderlying

-- | Navigation links i18n
navigationFieldsFor :: String -> Context String
navigationFieldsFor l = mconcat $ map (uncurry constField) $ case l of
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
