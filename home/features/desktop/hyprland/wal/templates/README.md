# Wallust template implementations

This is a simple repo that tries to gather some templates for wallust.

While there may be some agreement on how to style program X, the usual format
in this repo is to assign the colors to variables. However, if the program
config format doesn't allows it, a sample "theme" could be made, always
commenting why and what is being done.

# Spec
The templates should be in **v3** engine syntax format, which is a subset of Jinja2.

If the template is for some language, just name it `colors.ext`, where `ext` is the proper extention.

If the template, however, is for a program, use it's name on the file name, either `name.ext` or `name`.

## How to use
At the top of each file there is a short description of:
1. How to add the template to wallust.toml
2. How to implement it with the program.
