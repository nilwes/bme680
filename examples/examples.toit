// Copyright (C) 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import gpio
import i2c
import ..src.bme680

main:
  bus := i2c.Bus
    --sda=gpio.Pin 21
    --scl=gpio.Pin 22

  device := bus.device 0x77

  sensor := bme680 device
  
  print "Gas resistance: $(%.3f sensor.read_gas / 1000) kΩ"
  print "Pressure: $(%.1f sensor.read_pressure / 100) hPa"
  print "Humidity: $(%.1f sensor.read_humidity)%"
  print "Temperature: $(%.1f sensor.read_temperature)°C"
  
