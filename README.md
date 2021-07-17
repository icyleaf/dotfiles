icyleaf's dotfiles
==================

这里是个人整理的 dotfiles，但这个和大家看到的不太一样，这个配置文件数据更像是带安装和定制配置的。

大家可以按照需要选择性安装（目前还只能在配置文件修改）。如下是我个人安装配置的结构：

```bash
.
├── README.md
├── alfred
│   ├── Alfred.alfredpreferences
│   └── install.sh
├── bin
│   ├── bootstrap
│   └── macos
├── brew
│   ├── Brewfile
│   └── install.sh
├── editorconfig
│   └── editorconfig.symlink
├── functions
│   └── _lib.sh
├── git
│   ├── gitattributes.symlink
│   ├── gitconfig.local.symlink.example
│   ├── gitconfig.symlink
│   └── gitignore.symlink
├── gnupg
│   ├── gpg-agent.conf
│   └── install.sh
├── iterm2
│   ├── Preferences
│   ├── install.sh
│   └── themes
├── karabiner
│   ├── assets
│   ├── install.sh
│   └── karabiner.json
├── mas
│   └── install.sh
├── ruby
│   ├── gemrc.symlink
│   ├── install.sh
│   ├── irbrc.symlink
│   └── rvmrc.symlink
├── tmux
│   ├── install.sh
│   ├── tmux.conf.symlink
│   └── tmuxinator.symlink
├── vim
│   └── install.sh
├── vscode
│   ├── install.sh
│   └── syncLocalSettings.json.example
├── xcode
│   └── install.sh
└── zsh
    ├── install.sh
    ├── p10k.zsh
    └── zshrc.symlink
```

安装
--------

```bash
$ git clone http://gitlab.dev/icyleaf/dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles
$ ./bin/bootstrap
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
