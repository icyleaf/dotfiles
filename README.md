icyleaf's dotfiles
==================

这里是个人整理的 dotfiles，但这个和大家看到的不太一样，这个配置文件数据更像是带安装和定制配置的。

大家可以按照需要选择性安装（目前还只能在配置文件修改）。如下是我个人安装配置的结构：

```bash
.
├── README.md
├── bin
│   ├── bootstrap
│   ├── install
│   └── macos
├── brew
│   ├── Brewfile
│   └── install.sh
├── editorconfig
│   └── editorconfig.symlink
├── functions
│   └── _bash
├── git
│   ├── gitattributes.symlink
│   ├── gitconfig.local.symlink
│   ├── gitconfig.local.symlink.example
│   ├── gitconfig.symlink
│   └── gitignore.symlink
├── iterm2
│   ├── Preferences
│   │   └── com.googlecode.iterm2.plist
│   ├── install.sh
│   └── themes
│       └── seti.itermcolors
├── karabiner
│   ├── assets
│   │   └── complex_modifications
│   │       └── 60-keyboard.json
│   ├── install.sh
│   └── karabiner.json
├── ruby
│   ├── gemrc.symlink
│   └── irbrc.symlink
├── rvm
│   ├── install.sh
│   └── rvmrc.symlink
├── tmux
│   ├── install.sh
│   ├── tmux.conf.symlink
│   └── tmuxinator.symlink
│       ├── hpr.yml
│       └── qmobile.yml
├── vim
│   └── install.sh
├── vscode
│   ├── syncLocalSettings.json
│   └── syncLocalSettings.json.example
└── zsh
    ├── install.sh
    └── zshrc.symlink
```

安装
--------

```bash
$ git clone http://gitlab.dev/icyleaf/dotfiles.git
$ cd dotfiles
$ ./bin/bootstrap
$ ./bin/install
$ ./bin/macos
```

实现原理
--------

所有的配置都是以软连接的方式进行配置，修改哪一项都**只会**更新当前仓库的文件数据，如有需要可以备份并提交到 git 仓库。

疑惑解答
--------

直接问作者本人吧！

更多牛人配置
------------

https://dotfiles.github.io/
