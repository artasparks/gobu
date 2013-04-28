Gobu: A Go Build Tool
====

![Gobu Test Failure](http://i.imgur.com/uVg9sDa.png)

Gobu is simple Go Build tool for Vim.  The primary of Gobu improvement over a
default quickfix integration is that the entire output of a build or test is
put into the Gobu Window.  This means that we get the entire message -- no
truncation, no munging, *and* we still get the useful jump-to-error feature of
quickfix (by pressing enter while on the same line as a file path).

It exposes two command to the user:

      :GoBu -- build current package (does a go install <package>)
      :GoTe -- test current package

The easiest way to install is to install Vundle or Pathogen (or another vim
plugin manager manager)

      Bundle 'Kashomon/gobu'

## Examples:

### Panic!

![Gobu Panic](http://i.imgur.com/5eD6hSl.png)

### Build Failure

![Gobu Panic](http://i.imgur.com/rYQ9obJ.png)

