# bme680
Toit driver for the BME680 temperature, humidity, pressure, and gas sensor.

## VOC Sensor
The BME680 contains a small MOX sensor. The heated metal oxide changes resistance based on the volatile organic compounds (VOC) in the air, so it can be used to detect gasses & alcohols such as Ethanol, Alcohol, and Carbon Monoxide, and perform air quality measurements. Note it will give you one resistance value, with overall VOC content, but it cannot differentiate gasses or alcohols.

Please note this sensor, like all VOC/gas sensors, has variability, and to get precise measurements you will want to calibrate it against known sources! That said, for general environmental sensors, it will give you a good idea of trends and comparisons. We recommend that you run this sensor for 48 hours when you first receive it to "burn it in", and then 30 minutes in the desired mode every time the sensor is in use. This is because the sensitivity levels of the sensor will change during early use, and the resistance will slowly rise over time as the MOX warms up to its baseline reading.


## Usage

A simple usage example.

```
import bme680

main:
  ...
```

See the `examples` folder for more examples.

## References
BME680 Data sheet

https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme680-ds001.pdf

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/nilwes/bme680/issues
