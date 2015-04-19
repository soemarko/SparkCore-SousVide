# Rice Cooker Sous Vide with Spark Core

**Parts**

- [Spark Core](http://spark.io) ($40, can be replaced with $19 Spark Photon)
- Water proofed DS18B20 temperature sensor ($3-4)
- Solid State Relay ($3 from eBay)
- Old unused rice cooker ($0?)
- Extention cord, so I don't have to cut the rice cooker's cable.

More on [the setup on my blog](http://blog.soemarko.com/post/116313509168/diy-sous-vide-test-result-parts-spark-core).

**Codes**

- sous-vide.ino: the main controller; modify as needed
- DS18B20 and OneWire: thermometer sensor library
- PID and PID_AutoTune: PID and the auto tune library

The code is simple enough to just pasted in, you just need to add the access token and your Core device ID to the `Sous_Vide.pch`. The iOS app very basic and it's enough for anyone to implement their own style and polish to the app. So I probably won't update the iOS part anymore.

## License

As usual, my projects are released under [DBAD Public License](http://www.dbad-license.org/).
