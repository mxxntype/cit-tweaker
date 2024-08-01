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
    pack_path: directory              # The path to the resourcepack's files, usually contains files `pack.mcmeta`, `pack.png`
    --items: path = ./items.nuon      # The path to the file containing the additional items.
    --mix-bows-with-crossbows = false # If this flag is passed, the `bows` and `crossbows` arrays are merged and added to both bows and crossbows.
]: nothing -> nothing {
    let data: record = (open $items | into record)

    cd $pack_path

    # The amount of files the script has modified. I believe "silent"
    # scripts are bad, so this is some kind of result for the user.
    mut file_mod_count: int = 0

    let execution_time = timeit {
        for file in (glob **/*.properties) {
            let content: string = (open $file)
            let items: list<string> = ($content
                | lines
                | filter {|l| $l | str contains "items="})

            if ($items | is-not-empty) {
                mut modified: bool = false
                let relpath: string = ($file
                    | path split
                    | skip until {|$d| $d == cit}
                    | skip 1
                    | path join)

                mut items: list<string> = ($items
                    | first
                    | str replace "items=" ""
                    | str replace --all " " "\n"
                    | lines)

                let log_update = {|array_name: string| $"(ansi mb)($relpath)(ansi reset) with (ansi yb)($array_name)(ansi reset)" | log "Updating"}

                # Check if the file contains any blacklisted items, and remove those items if there are any.
                $items = ($items | filter {|item| not ($data.blacklisted_items | any {|blacklisted| $item == $blacklisted})})

                if ($items | any {|item| $item | str contains "_sword"}) {
                    do $log_update "$swords"
                    $items = ($items
                        | append $data.swords
                        | append $data.wands)
                }

                match $mix_bows_with_crossbows {
                    false => {
                        if ($items | any {|item| $item | str contains "minecraft:bow"}) {
                            do $log_update "$bows"
                            $items = ($items
                                | append $data.bows
                                | append $data.wands)
                        }

                        if ($items | any {|item| $item | str contains "minecraft:crossbow"}) {
                            do $log_update "$crossbows"
                            $items = ($items
                                | append $data.crossbows
                                | append $data.wands)
                        }
                    }

                    true => {
                        if (($items | any {|i| $i | str contains "minecraft:bow"}) or ($items | any {|i| $i | str contains "minecraft:crossbow"})) {
                            do $log_update "$bows + $crossbows"
                            $items = ($items
                                | append $data.wands
                                | append $data.bows
                                | append $data.crossbows)
                        }
                    }
                }

                if ($items | any {|item| $item | str contains "_pickaxe"}) {
                    do $log_update "$pickaxes"
                    $items = ($items | append $data.pickaxes)
                }

                if ($items | any {|item| $item | str contains "_axe"}) {
                    do $log_update "$axes"
                    $items = ($items | append $data.axes)
                }

                if ($items | any {|item| $item | str contains "_shovel"}) {
                    do $log_update "$shovels"
                    $items = ($items | append $data.shovels)
                }

                if ($items | any {|item| $item | str contains "_hoe"}) {
                    do $log_update "$hoes"
                    $items = ($items | append $data.hoes)
                }

                if ($items | any {|item| $item | str contains "_helmet"}) {
                    do $log_update "$helmets"
                    $items = ($items | append $data.helmets)
                }

                if ($items | any {|item| $item | str contains "_chestplate"}) {
                    do $log_update "$chestplates"
                    $items = ($items | append $data.chestplates)
                }

                if ($items | any {|item| $item | str contains "_leggings"}) {
                    do $log_update "$leggings"
                    $items = ($items | append $data.leggings)
                }

                if ($items | any {|item| $item | str contains "_boots"}) {
                    do $log_update "$boots"
                    $items = ($items | append $data.boots)
                }

                # Form the `items=` line, passing the $items through `uniq` to ensure nothing got duplicated somehow.
                let items_str: string = $"items=($items | uniq | str join ' ')\r"
                $content
                    | str replace --regex "items=.*" $items_str # Replace the original `items` array with the updated one.
                    | save --raw --force $file                  # Write the changes to the .properties file.
            }
        }
    }

    cd -

    $"Modified found (ansi cyan_bold)`.properties`(ansi reset) files in (ansi blue_bold)($execution_time)(ansi reset)" | log "    Done"
}

def "log" [status: string]: string -> nothing {
    print $"  (ansi green_bold)($status)(ansi reset) ($in)"
}
