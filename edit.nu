#!/usr/bin/env nu
# Get Nushell: https://www.nushell.sh

# I really like resoursepacks that have CIT renames for various items,
# because it's a really vanilla-friendly way to add some variety and depth
# to the already familiar items.
#
# However, they usually only contain definitions for Minecraft's native
# items (and that's absolutely expected), and I don't think there is any
# in-game way to use those cool CIT renames for modded gear. This script
# iterates through all of the `*.properties` files of a resourcepack,
# and adds more items (see above) to the `items=` array of each texture,
# based on some really simple guesses.
#
# If you're reading this from the CLI, see the source code for more info.
# The `items.nuon` file also contains some additional information.
#
# WARN: Only tested on 1.20.1 with NeoForge 47.1.106 the "CIT Resewn" mod.
def main [
    pack_path: directory         # The path to the resourcepack's files, usually contains files `pack.mcmeta`, `pack.png`
    --items: path = ./items.nuon # The path to the file containing the additional items.
]: nothing -> nothing {
    let data: record = (open $items | into record)

    cd $pack_path

    # The amount of files the script has modified. I believe "silent"
    # scripts are bad, so this is some kind of result for the user.
    mut modified_file_count: int = 0

    for file in (glob **/*.properties) {
        let content: string = (open $file)
        let items: list<string> = ($content
            | lines
            | filter {|l| $l | str contains "items="})

        if ($items | is-not-empty) {
            let relpath = $file | path split | skip until {|$d| $d == assets} | path join
            mut items: list<string> = ($items
                | first
                | str replace "items=" ""
                | str replace --all " " "\n"
                | lines)

            let has_blacklisted_items: bool = ($items | any {|item| $data.blacklisted_items | any {|blacklisted| $item == $blacklisted}})
            mut modified: bool = match $has_blacklisted_items {
                false => false
                true => {
                    $items = ($items | filter {|item| not ($data.blacklisted_items | any {|blacklisted| $item == $blacklisted})})
                    true
                }
            }

            if ($items | any {|item| $item | str contains "_sword"}) {
                print $"  (ansi gb)Adding(ansi reset) $swords to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.swords)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_pickaxe"}) {
                print $"  (ansi gb)Adding(ansi reset) $pickaxes to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.pickaxes)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_axe"}) {
                print $"  (ansi gb)Adding(ansi reset) $axes to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.axes)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_shovel"}) {
                print $"  (ansi gb)Adding(ansi reset) $shovels to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.shovels)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_hoe"}) {
                print $"  (ansi gb)Adding(ansi reset) $hoes to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.hoes)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_helmet"}) {
                print $"  (ansi gb)Adding(ansi reset) $helmets to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.helmets)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_chestplate"}) {
                print $"  (ansi gb)Adding(ansi reset) $chestplates to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.chestplates)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_leggings"}) {
                print $"  (ansi gb)Adding(ansi reset) $leggings to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.leggings)
                $modified = true
            }

            if ($items | any {|item| $item | str contains "_boots"}) {
                print $"  (ansi gb)Adding(ansi reset) $boots to (ansi yellow)($relpath)(ansi reset)"
                $items = ($items | append $data.boots)
                $modified = true
            }

            if $modified {
                let items_str: string = ("items=" + ($items | str join " ") + "\r")
                $content
                    | str replace --regex "items=.*" $items_str # Replace the original `items` array with the updated one.
                    | save --raw --force $file                  # Write the changes to the .properties file.

                $modified_file_count += 1
            }
        }
    }

    cd -

    print $"Modified (ansi cb)($modified_file_count)(ansi reset) files."
}
