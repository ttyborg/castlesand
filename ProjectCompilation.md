# Introduction #

This instruction explains how to compile a working project.


# Pre-requirements #

  * Microsoft Windows OS: XP or higher (we did not tested 95,98,Me,2000, but they would probably work as well)
  * Delphi (version 2009 or higher) or Lazarus (0.9 or higher)
  * SVN client (Tortoise SVN or any other of your choice)
  * OpenGL 1.5 compliant GPU
  * Original "Knights and Merchants: The Peasants Rebellion" data files

Optional (can be ignored or skipped with conditional switches):
  * madExcept installed
  * OpenAL drivers installed

# Walkthrough #

  1. Install SVN client if you don't have one. Tortoise SVN is good.
  1. Checkout project working copy onto your PC using SVN client. Right-click in a folder where you want the project to be (e.g. "C:\My Documents\") and select from drop-down menu "SVN Checkout". Specify checkout folder (e.g. "C:\My Documents\Castlesand\") and path to our repository, `"http://castlesand.googlecode.com/svn/trunk"`. Do not use "https" version unless you are added to the team - it will ask you for a password you do not have yet. SVN will do its job in couple of minutes.<br><code>*</code>From now on paths will be written as relative, so e.g. ".\Maps" means <code>"C:\My Documents\Castlesand\Maps"</code>
<ol><li>Copy resource files from your "Knights and Merchants: The Peasants Rebellion" installation. You need ".\data" folder, copy whole of it into project folder. When asked - replace all of the existing files/folders.<br>
</li><li>Now to revert several replaced files - Right-click inside project folder and select SVN > Revert. Revert all the changes made to project files in ".\data" folder.<br>
</li><li>Copy all the <code>*</code>.rx files from <code>".\data\gfx\res\"</code> to <code>".\SpriteResource\"</code> folder.<br>
</li><li>Launch the Delphi/Lazarus and open ".\Utils\RXXPacker\RXXPacker.dpr" project. Compile and launch it. Select all the available items and press "Repack". This will convert sprites to format we use in game.<br>
</li><li>You won't have our private network authentication unit, so open ".\KaM Remake.inc" file with Notepad and place a dot like so <code>"{.$DEFINE USESECUREAUTH}"</code>. This will make Delphi skip all the code within <code>USESECUREAUTH</code> clauses. This authentication unit makes it harder for someone to join a multiplayer game using an unofficial client that they compiled themselves. If you somehow have our private network authentication unit (or you wrote your own) then you can skip this step.<br>
</li><li>If you don't have madExcept installed, then open ".\KaM Remake.inc" file with Notepad and place a dot like so <code>"{.$DEFINE USE_MAD_EXCEPT}"</code>. This will make Delphi skip all the code within <code>USE_MAD_EXCEPT</code> clauses. If you have madExcept installed - skip this step.<br>
</li><li>Now you can open ".\KaM Remake.groupproj" (if you have Delphi XE+) project and compile the project and/or its utility tools. Or ".\KaM Remake.dpr" if you have older Delphi version.