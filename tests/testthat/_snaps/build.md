# protection against ~ deletion

    Code
      check_for_tilde_file(tempfile())
    Condition
      Error in `check_for_tilde_file()`:
      ! This package contains a file or directory named `~`. Because of a bug in older R versions (before R 4.0.0), building this package might delete your entire home directory!It is best to (carefully!) remove the file. rcmdcheck will exit now.

