## What is it? ##

`generate-imageasset-symbols` is a tiny little Mac command-line tool that creates a
header file containing `NSString` constants for the images in the given `.xcassets`
folder. Combined with a custom build step in your Xcode project and a bit of macro
magic, it can be used to automatically give compile-time checked keys for your
image names.

## License ##

`generate-imageasset-symbols` is licensed under three-clause BSD. The license document can be
found [here](https://github.com/iKenndac/generate-imageasset-symbols/blob/master/LICENSE.markdown).

## Building ##

1. Clone generate-imageasset-symbols using `$ git clone git://github.com/iKenndac/generate-imageasset-symbols.git`.
2. Open the project and build away!

## Usage ##

`$ generate-imageasset-symbols -assets <path to .xcassets folder> -out <output path>`

  * `-assets`  The path to a valid .xcassets folder.

  * `-out` The path to write the output header file to. Missing
    directories will be created along the way. If a file
    already exists at the given path, it will be
    overwritten.

