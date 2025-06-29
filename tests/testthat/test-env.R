test_that("set_env", {
  called <- FALSE
  local_mocked_bindings(ignore_env = function(...) called <<- TRUE)
  withr::local_envvar(RCMDCHECK_LOAD_CHECK_ENV = "false")

  desc <- desc::desc("!new")
  set_env(NULL, NULL, desc)
  expect_false(called)

  desc$set("Config/rcmdcheck/ignore-inconsequential-notes" = "false")
  set_env(NULL, NULL, desc)
  expect_false(called)

  desc$set("Config/rcmdcheck/ignore-inconsequential-notes" = "true")
  set_env(NULL, NULL, desc)
  expect_true(called)
})


test_that("ignore_env_config", {
  envs <- ignore_env_config()
  expect_s3_class(envs, "data.frame")
  expect_equal(names(envs), c("docs", "envvar", "value"))
  expect_equal(unname(sapply(envs, class)), rep("character", 3))
})

test_that("ignore_env", {
  do <- function() {
    ignore_env(c(foo = "bar"))
    expect_equal(Sys.getenv("foo"), "bar")
  }
  withr::local_envvar(foo = "notbar")
  do()
  expect_equal(Sys.getenv("foo"), "notbar")
})

test_that("load_env", {
  path_ <- NULL
  local_mocked_bindings(load_env_file = function(path, envir) path_ <<- path)

  withr::local_envvar(RCMDCHECK_LOAD_CHECK_ENV = "false")
  load_env("foo", "bar", "package")
  expect_null(path_)

  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
  envfile <- file.path(tmp, "pkg", "tools", "check.env")
  dir.create(dirname(envfile), recursive = TRUE, showWarnings = FALSE)
  cat("foo=bar\n#comment\n\nbar=foobar\n", file = envfile)

  withr::local_envvar(RCMDCHECK_LOAD_CHECK_ENV = "true")
  load_env(file.path(tmp, "pkg"))
  expect_true(file.exists(path_))
  path_ <- NULL

  withr::local_envvar(RCMDCHECK_LOAD_CHECK_ENV = NA)
  load_env(file.path(tmp, "pkg"))
  expect_true(file.exists(path_))
  path_ <- NULL

  tarfile <- tempfile(fileext = ".tar.gz")
  withr::with_dir(
    tmp,
    tar(tarfile, "pkg", tar = "internal")
  )

  load_env(tarfile, tarfile, "pkg")
  expect_false(is.null(path_))
  path_ <- NULL
})

test_that("load_env_file", {
  envfile <- tempfile()
  on.exit(unlink(envfile, recursive = TRUE), add = TRUE)
  cat("foo=bar\n#comment\n\nbar=foobar\n", file = envfile)

  withr::local_envvar(foo = "notbar", bar = NA)
  do <- function() {
    load_env_file(envfile)
    expect_equal(Sys.getenv("foo"), "bar")
    expect_equal(Sys.getenv("bar"), "foobar")
  }

  do()

  expect_equal(Sys.getenv("foo"), "notbar")
  expect_equal(Sys.getenv("bar", ""), "")
})

test_that("load_env_file error", {
  envfile <- tempfile()
  on.exit(unlink(envfile, recursive = TRUE), add = TRUE)
  cat("foo=bar\n#comment\n\nbarfoobar\n", file = envfile)

  withr::local_envvar(foo = "notbar", bar = NA)
  do <- function() {
    load_env_file(envfile)
  }

  expect_snapshot(error = TRUE, do())

  expect_equal(Sys.getenv("foo"), "notbar")
  expect_equal(Sys.getenv("bar", ""), "")
})
