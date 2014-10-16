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
main = hakyllWith myConfig $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "favicons/*" $ do
        route idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "templates/*" $ compile templateCompiler

    create [".htaccess"] $ do
        route idRoute
        compile $ makeItem ("Redirect 301 /test/index.html /test/en/" :: String)

    -- content/ -------------------------------------

    -- Project tags
    projectTagsEn <- buildTags "content/projects/*-en.markdown" (fromCapture "project-tags/*-en.html")
    projectTagsFi <- buildTags "content/projects/*-fi.markdown" (fromCapture "project-tags/*-fi.html")
    tagsRules projectTagsEn $ renderTagged projectCtx "templates/projects-en.html"
    tagsRules projectTagsFi $ renderTagged projectCtx "templates/projects-fi.html"

    -- Course tags
    coursesEn <- buildTags "content/courses/*/*-en.markdown" (fromCapture "course-tags/*-en.html")
    coursesFi <- buildTags "content/courses/*/*-fi.markdown" (fromCapture "course-tags/*-fi.html")
    tagsRules coursesEn $ renderTagged defaultContext "templates/courses-en.html"
    tagsRules coursesFi $ renderTagged defaultContext "templates/courses-fi.html"

    match "content/publications/*.pdf" $ do
        route $ gsubRoute "content/" (const "")
        compile $ copyFileCompiler >>= saveSnapshot "pdfs"

    match "content/*/**.markdown" $ do
        route contentRoute
        compile $ do
            ctx <- defaultContextWithLang
            getResourceBody >>= applyAsContent ctx

    match "content/*.markdown" $ do
        route contentRoute
        compile $ do

            lang <- getLang
            projectTags <- renderTagList $ if lang == "fi" then projectTagsFi else projectTagsEn
            courseTags  <- renderTagList $ if lang == "fi" then coursesFi else coursesEn
                           -- TODO ^ should use @Languages@ or smth

            ctx' <- defaultContextWithLang
            let ctx = listField "items" projectCtx projects
                    <> listField "publications" defaultContext publications
                    <> constField "project_tags" projectTags
                    <> listField "undergrad_courses" defaultContext (itemsAt "courses/undergrad")
                    <> listField "postgrad_courses" defaultContext (itemsAt "courses/postgrad")
                    <> constField "course_tags" courseTags
                    <> listField "bsc_topics" defaultContext (itemsAt "thesis/bsc")
                    <> listField "msc_topics" defaultContext (itemsAt "thesis/msc")
                    <> ctx'

            getResourceBody >>= applyAsContent ctx

--------------------------------------------------------------------------------

myConfig :: Configuration
myConfig = defaultConfiguration
    { deployCommand = "" }

renderTagged :: Context String -> Identifier -> String -> Pattern -> Rules ()
renderTagged itemCtx templ tag pat = do
    route idRoute
    compile $ do
        ctx' <- defaultContextWithLang
        let ctx = listField "items" itemCtx (loadAll pat)
                <> constField "tag" tag
                <> ctx'
        makeItem ""
            >>= loadAndApplyTemplate templ ctx 
            >>= applyAsContent ctx

--------------------------------------------------------------------------------

applyAsContent :: Context String -> Item String -> Compiler (Item String)
applyAsContent ctx item = 
    applyAsTemplate ctx item
    >>= return . renderPandocWith myPandocReaderOpt myPandocWriterOpt
    >>= loadAndApplyTemplate "templates/default.html" ctx
    >>= relativizeUrls

contentRoute :: Routes
contentRoute = gsubRoute "content/" (const "") `composeRoutes`
                customRoute setLang `composeRoutes`
                setExtension "html"

defaultContextWithLang :: Compiler (Context String)
defaultContextWithLang = do
    lang      <- getLang
    templangs <- mconcat . map (uncurry constField) <$> templateLanguages lang
    url       <- getUnderlying >>= liftM (fromMaybe "") . getRoute
    return $ constField "lang" lang
        <> languagesField "lang_choices" url lang
        <> templangs
        <> defaultContext

projectCtx :: Context String
projectCtx =
    dateField "year" "%Y" <>
    defaultContext

-- Items

projects :: Compiler [Item String]
projects = itemsAt "projects" >>= recentFirst

-- | The body is empty
publications :: Compiler [Item String]
publications = map (fmap $ const "") . reverse
    <$> (loadAllSnapshots "content/publications/*" "pdfs" :: Compiler [Item CopyFile])

itemsAt :: String -> Compiler [Item String]
itemsAt sub = do
    lang <- getLang
    loadAll $ fromGlob $ "content/" ++ sub ++ "/*-" ++ lang ++ ".*"

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

templateLanguages :: String -> Compiler Languages
templateLanguages lang =
    read <$> unsafeCompiler (readFile $ "templates-" ++ lang ++ ".conf")
