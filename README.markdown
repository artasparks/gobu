gobu: A Go Build Tool
====

Gobu is simple Go Build tool for Vim.  It exposes one command to the user:

      :GoBuilder

This will either:

  - Build the current package.
  - If you are in a \_test.go file:
    1. Test the current package
    2. If there is a compilation error when testing, do a build instead

The easiest way to install is to install Vundle and then do

      Bundle 'Kashomon/gobu'
