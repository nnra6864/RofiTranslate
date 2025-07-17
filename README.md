# Rofi Translate
A quick and simple translation tool utilizing Rofi.

<p align="center">
    <img src="/Media/RofiTranslate.png" alt="RofiTranslate">
</p>

# Installation
Clone the repository:
```
git clone https://github.com/nnra6864/RofiTranslate
```

Install dependencies *(Arch Example)*:
```
paru -S translate-shell
```

# Usage
Simply launch the script directly:
```
sh RofiTranslate.sh
```

Or even better, make a bind for it *(Hyprland Example)*:
```
bind = $mainMod ALT, T, exec, ~/Packages/RofiTranslate/RofiTranslate.sh
```

Once Rofi Translate is open, select the Input and Output Languages, type whatever you want to translate, and simply press Enter. Output will be copied to your clipboard.
