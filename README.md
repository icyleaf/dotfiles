# icyleaf's dotfiles

这里是个人整理的 dotfiles，但这个和大家看到的不太一样，这个配置文件数据更像是带安装和定制配置的。

大家可以按照需要选择性安装（目前还只能在配置文件修改）。

## 安装

脚本有依赖无法独立运行，建议先把仓库 clone 后独立运行自己所需的配置

```bash
$ git clone http://gitlab.dev/icyleaf/dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles
$ ./bin/bootstrap -h
$ ./bin/bootstrap

# macOS 快速配置
$ ./bin/macos
```

## 安全数据

配置必然后包含私密数据，仓库新增 sops + age 加密核心数据，目前加密的规则可见 [.sops.yaml](.sops.yaml) 文件。

### zsh 密钥

因 sops 目前未支持配置文件自动识别 dotenv 类型，需要手动指定：

```bash
# 解密
$ sops -d --output-type dotenv zsh/local.enc.zsh zsh/local.zsh

# 加密
$ sops -d --input-type dotenv zsh/local.zsh zsh/local.enc.zsh
```

## 实现原理

除了 `bin` 目录执行专项的快速配置脚本外，其他目录都是可独立运行的配置项。独立的配置都会包含一个 `install.sh` 来进行安装配置操作，且涉及配置的文件绝大多数都会以软连接的方式进行配置，修改哪一项都**只会**更新当前仓库的文件数据，如有需要可以备份并提交到 git 仓库。

## 疑惑解答

直接问作者本人吧！

更多牛人配置
------------

https://dotfiles.github.io/
