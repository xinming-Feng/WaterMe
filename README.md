# WaterMe
<img src="assets/images/waterme_title.png" width="80" height="66" alt="WaterMe">

- WaterMe is your plants' new best friend, keeping them hydrated and happy with smart soil moisture monitoring. 🌱

- Never forget to water your green companions again, thanks to personalized reminders based on each plant's unique needs. 🌱

- Track your plant's vital stats with real-time temperature and moisture data, all wrapped in a delightful pixel-art interface.🌱

- Connect real soil sensors to your virtual garden and watch your plants thrive both online and offline.🌱



## Getting Started
### Storyboard and User story
![301745191887_ pic](https://github.com/user-attachments/assets/f3e50059-84e8-4f82-865f-a3b2695cff36)
- Lisa isa busy office worker. At the same time, she isa plant lover. She has many different plants in her home. She needs to be watered every once in a while.
- When she buys a new plant, she will use her phone to use deviceid to connected the pot, bind the plant information and input it into the app. At the same time, a random Stardew Valley Story ui will be generated as the avatar of the plant.
- She can view the app's line chart of soil water content for each pot of plants and water the plants based on the data.

### Wireframe of APP
![Untitled](https://github.com/user-attachments/assets/170de56a-7cc9-40d4-914f-dc9f5673e51f)

### Physical device
This app needs to be used in conjunction with physical devices. Physical device is mainly used to detect the moisture of the soil in flowerpots and the indoor air temperature. And publish the data to the mqtt broker via Wi-Fi.

![431745204916_ pic_hd](https://github.com/user-attachments/assets/a0911945-e5b3-48ae-b1e4-d6d450da763f)

This physical device include:
- ESP-32(MCU)
- FC-28(Soil moisture sensor)
- DHT22(Temperature sensor)

How to use the physical device :

![441745204925_ pic_hd](https://github.com/user-attachments/assets/7de8a159-9a18-4e75-8d15-5e5a399a0ac5)


### APP pages
<div align="center" style="display: flex; gap: 10px; justify-content: center;">
  <img src="https://github.com/user-attachments/assets/ad7d1e83-4732-4de2-bad3-e0404073a189" width="45%" />
  <img src="https://github.com/user-attachments/assets/de7c73bf-9631-4554-b3f5-c1a47c92d7e4" width="45%" />
</div>

## Demo vedio

## How To Install The App
### Dependencies
```
 flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.2.2
  intl: ^0.19.0
  fl_chart: ^0.66.0
  image_picker: ^1.0.7
  path_provider: ^2.1.2
  firebase_core: ^2.25.4
  firebase_auth: ^4.16.0
  cloud_firestore: ^4.17.5
  flutter_native_splash: ^2.4.6
  mqtt_client: ^10.8.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.13.1

```
### Android device
![291745191590_ pic](https://github.com/user-attachments/assets/7e791c77-396f-49bd-bda1-c9f23e414d23)

√ Click on "Releases" in the upper right corner of the github project's home page, select the latest version and download the **.apk file**, then install it on your Android device to run it.

### Simulator
1. Clone the repository
   
   `https://github.com/xinming-Feng/WaterMe`
   
3. Install dependencies
   
   `flutter pub get`
   
5. Run the app
   
   `flutter run`

## Contact Details
xinminFeng

xinmingfeng_1@outlook.com
