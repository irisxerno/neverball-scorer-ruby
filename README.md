# neverball-scorer-ruby

This script reads your saved scores for neverball and displays a table of all your completions that surpass the hard preset scores along with a percentage of all completions. This could be useful in a 100% completion or a 100% speedrun to easily view your progress.

## basic usage

`gem install neverball-scorer-ruby`

`neverball-scorer-ruby -s ~/.neverball/Scores/`

![Screenshot of neverball-scorer-ruby TUI](/screenshot.png?raw=true "neverball-scorer-ruby TUI")

`{ /////// }`: Not unlocked

`{ ------- }`: Not completed

`{ T U C   }`: Best time, Best Unlock and All Coins remain uncompleted

`{         }`: All Completed
