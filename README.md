# What is this?
This is an archive of Usenet posts recovered from the Internet Archive, in groups relevant to the game of [NetHack](https://www.nethack.org/).
Groups archived here are:
* net.sources
* net.sources.games
* comp.sources.games
* comp.sources.games.bugs
* net.games.hack
* rec.games.hack
* rec.games.roguelike.nethack

About 540 posts from the UTZOO archive, not found in the mbox files, are also included.

# Where this came from
The file wget-list has the links to the original files on the [Internet Archive](https://www.archive.org). split-news.rb split them into individual posts and organized them into threads.
To get the initial state of this archive:
* start from an empty directory
* download the files in wget-list (`wget -c -i wget-list`)
* unzip the .zip files
* gunzip the .gz files
* run the split.rb program (`./split.rb *.mbox`)

# Why this is here
Google Groups isn't useful anymore. It mangles whitespace. Lately, it has been blocking direct links to posts.

# Organization
Posts are indexed under the targeted newsgroups. For each newsgroup, those posts that form a thread of two or more posts are placed together in a numbered directory. A directory called "single" gathers all posts that do not form
threads, or for which no other post in the thread is available.

# Format of posts
All posts are encoded as in the original mbox files. No effort is made to convert to UTF-8, deal with HTML or quoted-printable brain damage, or to unmangle whitespace.

# "HipCrime" and other misdeeds
A major denial of service attack hit Usenet from August 2007 to February 2008. rec.games.roguelike.nethack was specifically targeted. The perpetrator used the name "Hipcrime", and remains unknown.

Posts dated from 21 August 2007 to 6 February 2008 have been reviewed and the "Hipcrime" flood removed, along with some garden-variety spam, so that rec.games.roguelike.nethack will actually be useful for this period.

No other efforts have yet been made to remove spam from the archive.
