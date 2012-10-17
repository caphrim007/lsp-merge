# lsp-merge

A tool that allows you to merge Nutcracker LSP 2.0 XML output files into LightShowPro 2.5 UserPatterns.xml files

## Getting started

You need Ruby installed and working on your computer. The easiest way to do this is with [RVM](https://rvm.io/)

```bash
tarupp@catbot:~$ curl -L get.rvm.io | bash -s stable

... follow instructions ...

tarupp@catbot:~$ rvm install 1.9.3

... follow instructions ...
```

After Ruby has been installed, you can install all of the dependencies for `lsp-merge` using the `bundle` command
from inside the `lsp-merge` directory.

```bash

tarupp@catbot:~/lsp-merge$ bundle install
```

## Using it

The script runs from the command line. The usage options are simple:

```
tarupp@catbot:~/lsp-merge$ ruby merge.rb --help
Usage: merge.rb [options]

Merge Options:
        --input INPUT                Comma separated list of files to use as input. Files are merged in the order they are listed
        --output FILENAME            Filename to write the merged output to (default: UserPatterns.xml.new)
        --proper                     Specify that proper XML merging be done. This can take a long time for large files (default: false)

General Options:
    -h, --help                       Show this message
        --version                    Show version

Debugging Options:
        --noop                       Do not perform any actions, only print out what would be done
tarupp@catbot:~/lsp-merge$
```

## Proper vs Fast

This script includes an option for proper XML parsing and "fast" XML parsing.

Which should you use?

Well, by default, the fast option in used. The way the fast parser behaves is potentially prone to error.
It does not use a DOM or SAX XML parser. It just opens your files, scans them line-by-line, and looks for
where the <Pattern> tags are.

Clearly this can lead to malformed XML documents if a tag is missed in the parsing.

The upside to the fast parser is that it is fast. How fast?

**Proper Parser**
```
tarupp@catbot:~/lsp-merge$ ruby merge.rb --input xml/orig/UserPatterns.xml,xml/orig/merge_me.xml 
D, [2012-10-17T14:20:13.030680 #11500] DEBUG -- : Will write output to UserPatterns.xml.new
D, [2012-10-17T14:20:13.032399 #11500] DEBUG -- : Opening UserPatterns.xml.new file
D, [2012-10-17T14:20:13.032794 #11500] DEBUG -- : Merging 2 files
D, [2012-10-17T14:20:13.033092 #11500] DEBUG -- : Opening xml/orig/UserPatterns.xml file
D, [2012-10-17T14:20:13.033394 #11500] DEBUG -- : Parsing XML from xml/orig/UserPatterns.xml. This may take a while if the file is large
D, [2012-10-17T14:53:56.513055 #11500] DEBUG -- : Opening xml/orig/merge_me.xml file
D, [2012-10-17T14:53:56.513605 #11500] DEBUG -- : Parsing XML from xml/orig/merge_me.xml. This may take a while if the file is large
Time elapsed 2030.09169897 seconds
tarupp@catbot:~/lsp-merge$
```

**Fast Parser**
```
tarupp@catbot:~/lsp-merge$ ruby merge.rb --input xml/orig/UserPatterns.xml,xml/orig/merge_me.xml
D, [2012-10-17T15:44:18.793662 #13596] DEBUG -- : Will write output to UserPatterns.xml.new
D, [2012-10-17T15:44:18.794298 #13596] DEBUG -- : Opening UserPatterns.xml.new file for writing
D, [2012-10-17T15:44:18.794881 #13596] DEBUG -- : Merging 2 files
D, [2012-10-17T15:44:18.795207 #13596] DEBUG -- : Opening xml/orig/UserPatterns.xml file
D, [2012-10-17T15:44:42.458664 #13596] DEBUG -- : Opening xml/orig/merge_me.xml file
Time elapsed 24.55157722 seconds
tarupp@catbot:~/lsp-merge$
```

33 minutes vs. 24 seconds

So use the default fast parser until you run into something that breaks it, and then fallback to the
proper parser.

You can use the proper parser by specifying the `--proper` flag

## Resources

* [Nutcracker](http://meighan.net/nutcracker)
* [LightShowPro](http://lightshowpro.com)

## Contributing

[Fork the project](https://github.com/caphrim007/lsp-merge) and send pull requests.
