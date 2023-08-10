# Dotfiles
Linux Configuration Files

## Commands

Soft Symbolic Link
```ln -s <file path to point to> <new file path>```

Check if path is symlink
 ```$ ls -l``` 

list broken links
```find <search directory> -xtype l```

## Usage

Run ```mass_linkup.sh``` to create links for current config files

Run ```mass_cleanup.sh``` to delete links for current config files

