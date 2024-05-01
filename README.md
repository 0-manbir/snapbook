![Banner](https://github.com/0-manbir/snapbook/assets/144022685/fd2a1424-5f59-46f7-b7fa-7656edcb8757)

# SnapBook

Snapbook is a photo journaling app!

## Quick FAQs:

**SDK** - Flutter\
**Language** - Dart

**Platform** - Android\
**APK File Size** - 21.5 MB

**Snaps Location** - storage/emulated/0/Pictures/SnapBook\
**Database Location** - storage/emulated/0/Documents/\
**Sample Database Name** - snapbook_20240301_072101.db

The database file saved on your device stores the image path, date-time and caption of each snap.

## Screenshots

<img src="https://github.com/0-manbir/snapbook/assets/144022685/fdda3ed7-ccca-4197-9e47-605e347aa829" height="300" alt="gallery view">
<img src="https://github.com/0-manbir/snapbook/assets/144022685/3f0be329-b3b0-4f99-8301-528d7f968bc1" height="300" alt="throwback">
<img src="https://github.com/0-manbir/snapbook/assets/144022685/68dc9c51-fd5d-4661-bad5-a1cccb79f674" height="300" alt="calendar">
<img src="https://github.com/0-manbir/snapbook/assets/144022685/6ae9fb5b-598d-4c3f-954a-7b0796de81fb" height="300" alt="calendar">
<img src="https://github.com/0-manbir/snapbook/assets/144022685/af68fc67-8201-4fea-98d6-960f7a0463e0" height="300" alt="caption">

## Features

### Gallery View

* Add a Snap
   - Click a picture (camera)
   - Pick a file (gallery)
* Add a caption
   - Text after a '#' is ignored when displayed in the bottom sheet (as in photo 2 below). But it can be used to search for a caption.

* Other Features
   - View an image (click on the image to open it in gallery.
   - Edit the caption of the image.
   - Share image along with the caption

<hr width="50%">

### Throwback

Select a date, and check the Snaps uploaded on that date.
<hr width="50%">

### Calendar

Highlights the days when a Snap was clicked.
Click on a day to view the Snap clicked on that day. (works _most_ of the time)
<hr width="50%">

### Settings / Stats

* Number of snaps clicked
    * this month
    * previous month
    * this year
    * previous year
* Import / Export Database

<hr width="50%">

## Edit Source Code

Clone the project

```bash
  git clone https://github.com/0-manbir/snapbook.git
```

Go to the project directory

```bash
  cd snapbook
```

Build APK File

```bash
  flutter build apk
```

