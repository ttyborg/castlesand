# Basic steps #

  1. Browse to the folder Campaigns under your KaM Remake folder
  1. Create a new folder with the name of your campaign, for example KaM Remake\Campaigns\My Campaign
  1. Run `CampaignBuilder.exe` from the main KaM Remake folder
  1. Enter a 3 letter short name for your campaign
  1. Click Load Picture and select an image for the map background on the briefing screen
  1. Set the map count
  1. Select each mission and drag the flag to the correct location on the map. You can also add nodes which are shown as dots on the map, choose briefing text position.
  1. Click Save and save it as info.cmp under your campaign folder, for example Campaigns\My Campaign\info.cmp. This will also save images.rxx which contains the map background image.
  1. Create a file text.eng.libx under your campaign folder, for example Campaigns\My Campaign\text.eng.libx. Open it in a text editor and enter the required text (look at the original campaigns for the file format, 0 is the title, 1 is the mission shortcode, 10 and onwards is mission briefings)
  1. For each mission of your campaign, create a folder under your campaign folder using your 3 letter short code and 2 digit mission number, for example Campaigns\My Campaign\MYC01.
  1. In each mission folder put the .map and .dat files for your mission, for example Campaigns\My Campaign\MYC01\MYC01.map

If you are unsure look at the original campaigns and make sure you have the same folder structure.

# Optional steps #

  * **Translations:** Run `TranslationManager.exe` from the main KaM Remake folder and select your campaign text file, for example Campaigns\My Campaign\text.eng.libx. Enter translations for your campaign in the appropriate boxes and click save. Languages which do not have a translation will use English instead.
  * **Audio:** Place the mission briefing audio as MP3 files in each mission folder, for example Campaigns\My Campaign\MYC01\MYC01.eng.mp3. You can provide the audio in any language by using the appropriate language code instead of eng.