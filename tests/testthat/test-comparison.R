test_that("basic metadata stored in comparison object", {
  cf <- compare_check_files(
    test_path("REDCapR-ok.log"),
    test_path("REDCapR-fail.log")
  )
  expect_equal(cf$package, "REDCapR")
  expect_equal(cf$versions, c("0.9.8", "0.9.8"))
})

test_that("status correctly computed when both checks are ok", {
  cf <- compare_check_files(
    test_path("minimal-ok.log"),
    test_path("minimal-ok.log")
  )
  expect_equal(cf$status, "+")
})

cli::test_that_cli("print message displays informative output", {
  skip_on_cran()
  cf <- compare_check_files(
    test_path("minimal-ee.log"),
    test_path("minimal-ewn.log")
  )

  expect_snapshot(
    print(summary(cf))
  )
})
