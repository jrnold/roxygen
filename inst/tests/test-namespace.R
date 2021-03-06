context("Namespace")
roc <- namespace_roclet()

test_that("export detects object name", {
  out <- roc_proc_text(roc, "#' @export\na <- function(){}")
  expect_equal(out, 'export(a)')
})

test_that("export escapes quotes name if needed", {
  out <- roc_proc_text(roc, "#' @export\n'a<-' <- function(){}")
  expect_equal(out, 'export("a<-")')
})

test_that("export escapes tricky names", {
  out <- roc_proc_text(roc, "#' @export\n`%||%` <- function(){}")
  expect_equal(out, 'export("%||%")')
  out <- roc_proc_text(roc, "#' @export\n`%'%` <- function(){}")
  expect_equal(out, 'export("%\'%")')
  out <- roc_proc_text(roc, "#' @export\n`%\"%` <- function(){}")
  expect_equal(out, 'export("%\\"%")')
  out <- roc_proc_text(roc, "#' @export\n`%\"%` <- function(){}")
  expect_equal(out, 'export("%\\"%")')
  out <- roc_proc_text(roc, "#' @export\n`%\\\\%` <- function(){}")
  expect_equal(out, 'export("%\\\\%")')
})

test_that("export parameter overrides default", {
  out <- roc_proc_text(roc, "#' @export b\na <- function(){}")
  expect_equal(out, 'export(b)')
})

test_that("multiple export parameters generate multiple exports", {
  out <- roc_proc_text(roc, "
    #' @export a b
    a <- function(){}")
  expect_equal(out, c('export(a)', 'export(b)'))
})


test_that("export detects S4 class", {
  out <- roc_proc_text(roc, "#' @export\nsetClass('a')")
  expect_equal(out, 'exportClasses(a)')
})

test_that("export detects S3 method", {
  out <- roc_proc_text(roc, "#' @export\nmean.foo <- function(x) 'foo'")
  expect_equal(out, 'S3method(mean,foo)')
})

test_that("exportClass overrides default class name", {
  out <- roc_proc_text(roc, "#' @exportClass b\nsetClass('a')")
  expect_equal(out, 'exportClasses(b)')
})

test_that("export detects method name", {
  out <- roc_proc_text(roc, "
    #' @export\n
    setMethod('max', 'a', function(x, ...) x[1])")
  expect_equal(out, 'exportMethods(max)')
})

test_that("export method escapes if needed", {
  out <- roc_proc_text(roc, "
    setGeneric('x<-', function(x, value) standardGeneric('x<-'))
    #' @export\n
    setMethod('x<-', 'a', function(x, value) value)")
  expect_equal(out, 'exportMethods("x<-")')
})

test_that("export uses name if no object present", {
  out <- roc_proc_text(roc, "
    #' Title
    #' 
    #' @export
    #' @name x
    NULL
  ")
  expect_equal(out, 'export(x)')
})


test_that("default export uses exportClass for RC objects", {
  out <- roc_proc_text(roc, "
    #' Title
    #' 
    #' @export
    x <- setRefClass('X')
  ")
  expect_equal(out, 'exportClasses(X)')
})

test_that("exportMethod overrides default method name", {
  out <- roc_proc_text(roc, "
    #' @exportMethod c
    setMethod('max', 'a', function(x, ...) x[1])")
  expect_equal(out, 'exportMethods(c)')
})

test_that("other namespace tags produce correct output", {
  out <- roc_proc_text(roc, "
    #' @exportPattern test
    #' @S3method test test
    #' @import test
    #' @importFrom test test1 test2
    #' @importClassesFrom test test1 test2
    #' @importMethodsFrom test test1 test2
    NULL")

  expect_equal(sort(out), sort(c(
    "exportPattern(test)",
    "S3method(test,test)",
    "import(test)",
    "importFrom(test,test1)",
    "importFrom(test,test2)",
    "importClassesFrom(test,test1)",
    "importClassesFrom(test,test2)",
    "importMethodsFrom(test,test1)",
    "importMethodsFrom(test,test2)"
  )))
})

test_that("multiline importFrom parsed correctly", {
  out <- roc_proc_text(roc, "
    #' @importFrom test test1
    #'   test2
    NULL
  ")
  expect_equal(sort(out), sort(c(
    "importFrom(test,test1)",
    "importFrom(test,test2)"
  )))
})

test_that("useDynLib imports only selected functions", {
  out <- roc_proc_text(roc, "
    #' @useDynLib test
    #' @useDynLib test a
    #' @useDynLib test a b
    NULL")

    expect_equal(sort(out), sort(
      c("useDynLib(test)", "useDynLib(test,a)", "useDynLib(test,b)")))
})

test_that("useDynLib doesn't quote if comma present", {
  out <- roc_proc_text(roc, "
    #' @useDynLib test, .registration = TRUE
    NULL")
  
  expect_equal(sort(out), "useDynLib(test, .registration = TRUE)")
})

test_that("empty NAMESPACE generates zero-length vector", {
  base_path <- normalizePath("empty")
  parsed <- parse_package(base_path, source_package)
  
  roc <- namespace_roclet()
  results <- roc_process(roc, parsed, base_path)
  expect_equal(results, character())
})
