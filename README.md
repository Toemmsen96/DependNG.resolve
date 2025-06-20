# gmsgDownloader
 Automatically downloads GMSG / Multislot if not found, just needs to be added to Plugins.

## More Info / detailed instructions:
[Toemmsen.ch Website](https://toemmsen.ch/posts/dependency_resolver/)

## Dependency Resolver Installer UI
This now features a dependency installer UI for easy integration into your own mod.

To use, load it with GMSG / MultiSlot's UI in the Utils-Tab under the advanced options.
As an alternative, you can load it by entering `extensions.load("tommot_depInstallerUi")` in the game's console.

You only need this to be installed in your game for it to work (It will automatically install GMSG / MultiSlot if it isn't already, may change in the future)


A full documentation on the website is on the way.

<details>
<summary>Dependency Installer UI</summary>

![UI](ghImages/installerUI.png)
</details>

## Usage for other mods
This kind of acts like a simple version of dependency resolving and can be easily adjusted to work for other mods etc. 
### Stuff needed to change for own mods (ONLY NEEDED IF DOING MANUALLY WITHOUT UI)
- Copy the lua and script folders with its content to the root of your mod
<details>
<summary>Example how it looks in file structure</summary>

![pasted example](ghImages/pastedExample.png)
</details>

- Choose a fitting name, for example the required-mod-ID+Downloader as "modname"
➡ Here we take gmsgDownloader as "modname" instead, from here always enter your chosen "modname"
- change foldername from /scripts/gmsgDownloader to /scripts/"modname"
- change /lua/ge/extensions/tommot/gmsgDownloader.lua to /lua/ge/extensions/"yourname"/"modname".lua
- edit the following line in /scripts/"modname"/modScript.lua so this reflects your name and modname 
```lua 
setExtensionUnloadMode("'yourname'_'modname'","manual")
``` 
<details>
<summary>Example for this specific mod</summary>

![modScript.lua example](ghImages/modScript.png)
</details>

- edit /lua/ge/extensions/"yourname"/"modname".lua:
find stuff to edit below 
```-- START OF ADJUSTMENTS \/ EDIT BELOW THIS LINE \/```
![gmsgDownloader.lua example](ghImages/luaToEdit.png)


### TODO
<details>
<summary>Current todo list:</summary>

- [ ] Add version check (with repo)
- [x] Variables for easier config (dev) *implemented*
</details>
