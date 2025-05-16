// Copyright C 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

// BME680 data sheet: https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme680-ds001.pdf

import binary
import serial.device as serial
import serial.registers as serial

I2C-ADDRESS     ::= 0x76
I2C-ADDRESS-ALT ::= 0x77

/**
Driver for the Bosch BME680 environmental sensor, using I2C.
*/
class Driver:
  // Chip ID address.
  static CHIP-ID-REG_                     ::=  0xD0

  // BME68X unique chip identifier.
  static CHIP-ID_                         ::=  0x61

  // Soft reset command.
  static SOFT-RESET-CMD_                  ::=  0xB6

  // IIR Filter config.
  static IIR-FILTER-CONFIG-REG_           ::=  0x75

  // 0th gas heater resistance.
  static RES-HEAT-REG0_                   ::=  0x5A

  // Gas measurement ctrl regs.
  static CTRL-GAS-REG_                    ::=  0x71

  // 0th gas heater wait.
  static GAS-WAIT-REG0_                   ::=  0x64

  // Humidity oversampling.
  static CTRL-HUM-REG_                    ::=  0x72

  // Temp, Pressure oversampling, and Force mode (Read sensors only on demand).
  static CTRL-MEAS-REG_                   ::=  0x74

  // Soft reset address.
  static SOFT-RESET-REG_                  ::=  0xE0

  // Heater temp stability.
  static HEAT-STAB-REG_                   ::=  0x2B // Bit 4.

  // Validity of gas measurement.
  static GAS-VALID-REG_                   ::=  0x2B // Bit 5.

  // THP and gas measuring indicator bits.
  static MEAS-STATUS-REG_                 ::=  0x1D

  // Data registers for THPG.
  static TEMPDATA-REG_                    ::=  0x22 // Data stored in 3 consecutive bytes (20 bits).
  static HUMDATA-REG_                     ::=  0x25 // Data stored in 2 consecutive bytes (16 bits).
  static PRESSDATA-REG_                   ::=  0x1F // Data stored in 3 consecutive bytes (20 bits).
  static GASDATA-REG_                     ::=  0x2A // Data stored in 2 consecutive bytes (10 bits).

  // Calibration data registers.
  static PAR-T1-REG_                      ::=  0xE9 // 16 bit.
  static PAR-T2-REG_                      ::=  0x8A // 16 bit.
  static PAR-T3-REG_                      ::=  0x8C //  8 bit.
  static PAR-P1-REG_                      ::=  0x8E // 16 bit.
  static PAR-P2-REG_                      ::=  0x90 // 16 bit.
  static PAR-P3-REG_                      ::=  0x92 //  8 bit.
  static PAR-P4-REG_                      ::=  0x94 // 16 bit.
  static PAR-P5-REG_                      ::=  0x96 // 16 bit.
  static PAR-P6-REG_                      ::=  0x99 //  8 bit.
  static PAR-P7-REG_                      ::=  0x98 //  8 bit.
  static PAR-P8-REG_                      ::=  0x9C // 16 bit.
  static PAR-P9-REG_                      ::=  0x9E // 16 bit.
  static PAR-P10-REG_                     ::=  0xA0 //  8 bit.
  static PAR-H1-REG-LSB_                  ::=  0xE2
  static PAR-H1-REG-MSB_                  ::=  0xE3
  static PAR-H2-REG-LSB_                  ::=  0xE2
  static PAR-H2-REG-MSB_                  ::=  0xE1
  static PAR-H3-REG_                      ::=  0xE4 //  8 bit.
  static PAR-H4-REG_                      ::=  0xE5 //  8 bit.
  static PAR-H5-REG_                      ::=  0xE6 //  8 bit.
  static PAR-H6-REG_                      ::=  0xE7 //  8 bit.
  static PAR-H7-REG_                      ::=  0xE8 //  8 bit.
  static PAR-GH1-REG_                     ::=  0xED //  8 bit.
  static PAR-GH2-REG_                     ::=  0xEB // 16 bit.
  static PAR-GH3-REG_                     ::=  0xEE //  8 bit.
  static RES-HEAT-RANGE-REG_              ::=  0x02 //  8 bit.
  static RES-HEAT-VAL-REG_                ::=  0x00 //  8 bit, signed.
  static RANGE-SW-ERR-REG_                ::=  0x04

  reg_/serial.Registers ::= ?

  // Calibration data variables
  par-T1_          := null
  par-T2_          := null
  par-T3_          := null
  par-P1_          := null
  par-P2_          := null
  par-P3_          := null
  par-P4_          := null
  par-P5_          := null
  par-P6_          := null
  par-P7_          := null
  par-P8_          := null
  par-P9_          := null
  par-P10_         := null
  par-H1_          := null
  par-H2_          := null
  par-H3_          := null
  par-H4_          := null
  par-H5_          := null
  par-H6_          := null
  par-H7_          := null
  par-GH1_         := null
  par-GH2_         := null
  par-GH3_         := null
  res-heat-range_  := null
  res-heat-val_    := null
  range-sw-err_    := null

  temp-comp_ := 0
  t-fine_    := 0

  plate-temp_ ::= 300 // Gas sensor will heat to this temp in Celsius.

  // ADC Ranges used for gas resistance calculations.
  const-array1_ ::= [1, 1, 1, 1, 1, 0.99, 1, 0.992, 1, 1, 0.998, 0.995, 1, 0.99, 1, 1]
  const-array2_ ::= [8000000, 4000000, 2000000, 1000000, 499500.4995,
                    248262.1648, 125000, 63004.03226, 31281.28128, 15625,
                    7812.5, 3906.25, 1953.125, 976.5625, 488.28125, 244.140625]

  constructor dev/serial.Device:
    reg_ = dev.registers

    // Reset device.
    reg_.write-u8 SOFT-RESET-REG_ SOFT-RESET-CMD_
    sleep --ms=5

    // Check chip ID.
    id := reg_.read-u8 CHIP-ID-REG_
    if id != CHIP-ID_: throw "INVALID_CHIP"

    read-calibration-data_

    // Sleep mode. No measurement until we say so.

    // 1x oversampling hum.
    reg_.write-u8 CTRL-HUM-REG_ 0b00_000_001

    // 1x oversampling temp. 1x oversampling press.
    reg_.write-u8 CTRL-MEAS-REG_ 0b001_001_00

    // No IIR filter.
    reg_.write-u8 IIR-FILTER-CONFIG-REG_ 0b000_000_00

    // Set to not run_gas and choose heater resistance at 0th position.
    reg_.write-u8 CTRL-GAS-REG_ 0b000_0_0000

    // Heating time for gas plate in ms.
    reg_.write-u8 GAS-WAIT-REG0_ 0b01_111111 // 4 x 64 ms = 256 ms.

  /**
  Reads the temperature and returns it in degrees Celsius.
  */
  read-temperature -> float:
    measure_
    return temp-comp_

  /**
  Reads the relative humidity and returns it as a percent in the range `0.0 - 100.0`.
  */
  read-humidity -> float:
    reg_.write-u8 CTRL-HUM-REG_ 0b0000_0001 // 1x oversampling.
    measure_
    hum-adc  := reg_.read-u16-be HUMDATA-REG_

    // Datasheet, page 20.
    var1 := hum-adc - ((par-H1_ * 16.0) + ((par-H3_ / 2.0) * temp-comp_))
    var2 := var1 * ((par-H2_ / 262144.0) * (1.0 + ((par-H4_ / 16384.0) *
      temp-comp_) + ((par-H5_ / 1048576.0) * temp-comp_ * temp-comp_)))
    var3 := par-H6_ / 16384.0
    var4 := par-H7_ / 2097152.0
    hum-comp := var2 + ((var3 + (var4 * temp-comp_)) * var2 * var2)

    return hum-comp

  /**
  Reads the barometric pressure and returns it in Pascals.
  */
  read-pressure -> float:
    measure_
    press-adc := reg_.read-u24-be PRESSDATA-REG_
    press-adc >>= 4

    // Datasheet, page 18.
    var1 := ((t-fine_ / 2.0) - 64000.0)
    var2 := var1 * var1 * (par-P6_ / 131072.0)
    var2 = var2 + (var1 * par-P5_ * 2.0)
    var2 = (var2 / 4.0) + (par-P4_ * 65536.0)
    var1 = (((par-P3_ * var1 * var1) / 16384.0) + (par-P2_ * var1)) / 524288.0
    var1 = (1.0 + (var1 / 32768.0)) * par-P1_
    calc-pres := 1048576.0 - press-adc

    // Avoid exception caused by division by zero
    if var1 == 0: return 0.0

    calc-pres = ((calc-pres - (var2 / 4096.0)) * 6250.0) / var1
    var1 = (par-P9_ * calc-pres * calc-pres) / 2147483648.0
    var2 = calc-pres * (par-P8_ / 32768.0)
    var3 := (calc-pres / 256.0) * (calc-pres / 256.0) * (calc-pres / 256.0) * (par-P10_ / 131072.0)
    press-comp := calc-pres + (var1 + var2 + var3 + (par-P7_ * 128.0)) / 16.0

    return press-comp + 900.0 // 9 -> Calibration to known QNH.

  /**
  Reads the gas resistance and returns it in Ohm.
  */
  read-gas -> float:
    //Set run_gas and choose heater resistance at 0th position
    reg_.write-u8 CTRL-GAS-REG_ 0b000_1_0000

    // Heater resistance calculation and storage. This is dependent on the
    // ambient temperature. Hence it must be calculated just prior to gas measurement.
    res-heat := calculate-res-heat
    reg_.write-u8 RES-HEAT-REG0_ res-heat

    measure_

    // Set not run_gas and choose heater resistance at 0th position.
    reg_.write-u8 CTRL-GAS-REG_ 0b000_0_0000

    if ((reg_.read-u8 HEAT-STAB-REG_) & 0b00_1_00000)  == 0:
      print "No valid gas measurement"
      return -1.0

    if ((reg_.read-u8 HEAT-STAB-REG_) & 0b000_1_0000)  == 0:
      print "Gas heater temperature not stable"
      return -1.0

    gas-adc := reg_.read-u16-be GASDATA-REG_
    gas-adc >>= 6

    gas-range := (reg_.read-u8 HEAT-STAB-REG_) & 0b0000_1111

    // Datasheet, page 22.
    var1 := (1340.0 + 5.0 * range-sw-err_) * const-array1_[gas-range]
    gas-res := var1 * const-array2_[gas-range] / (gas-adc - 512.0 + var1)
    return gas-res

  /**
  Calculates the goal gas heater plat resistance and returns it.
  */
  calculate-res-heat -> int:
    // Measure the ambient temperature, which is stored in temp_comp_.
    measure_

    // Datasheet, page 21.
    var1 := (par-GH1_ / 16.0) + 49.0
    var2 := ((par-GH2_ / 32768.0) * 0.0005) + 0.00235
    var3 := par-GH3_ / 1024.0
    var4 := var1 * (1.0 + (var2 * plate-temp_))
    var5 := var4 + (var3 * temp-comp_)
    res-heat := (3.4 * ((var5 * (4.0 / (4.0 + res-heat-range_)) *
      (1.0 / (1.0 + (res-heat-val_ * 0.002)))) - 25)).to-int

    return res-heat

  /**
  Performs sensor readout into data registers.
  */
  measure_:
    reg_.write-u8 CTRL-MEAS-REG_ 0b001_001_01

    wait-for-measurement_

    temp-adc := reg_.read-u24-be TEMPDATA-REG_

    temp-adc >>= 4

    // Datasheet, page 17.
    var1 := ((temp-adc / 16384.0) - (par-T1_ / 1024.0)) * par-T2_
    var2 := (((temp-adc / 131072.0) - (par-T1_ / 8192.0))
      * (temp-adc / 131072.0) - (par-T1_ / 8192.0))
      * (par-T3_ * 16.0)
    t-fine_ = var1 + var2
    temp-comp_ = t-fine_ / 5120.0

  wait-for-measurement_:
    // If maximum gas heater wait time is used (4096ms) it takes roughly
    // 90 iterations before the measurement is done.
    100.repeat:
      val := reg_.read-u8 MEAS-STATUS-REG_
      // MSB bit indicates new measurement values ready.
      if (val >> 7) & 1 == 1: return
      sleep --ms=it + 1  // Back off slowly.
    throw "BME680: Unable to measure TPHG"

  /**
  Reads calibration data stored in sensor memory.
  */
  read-calibration-data_:
    // Read temperature calibration.
    par-T1_ = reg_.read-u16-le PAR-T1-REG_
    par-T2_ = reg_.read-i16-le PAR-T2-REG_
    par-T3_ = reg_.read-i8 PAR-T3-REG_

    // Read pressure calibration.
    par-P1_  = reg_.read-u16-le  PAR-P1-REG_
    par-P2_  = reg_.read-i16-le  PAR-P2-REG_
    par-P3_  = reg_.read-i8      PAR-P3-REG_
    par-P4_  = reg_.read-i16-le  PAR-P4-REG_
    par-P5_  = reg_.read-i16-le  PAR-P5-REG_
    par-P6_  = reg_.read-i8      PAR-P6-REG_
    par-P7_  = reg_.read-i8      PAR-P7-REG_
    par-P8_  = reg_.read-i16-le  PAR-P8-REG_
    par-P9_  = reg_.read-i16-le  PAR-P9-REG_
    par-P10_ = reg_.read-i8     PAR-P10-REG_

    // Read humidity calibration.
    par-H1_  = ((reg_.read-u8  PAR-H1-REG-MSB_) << 4) | ((reg_.read-u8 PAR-H1-REG-LSB_) & 0b00001111)
    par-H2_  = ((reg_.read-u8  PAR-H2-REG-MSB_) << 4) | ((reg_.read-u8 PAR-H2-REG-LSB_) >> 4);
    par-H3_  =   reg_.read-i8  PAR-H3-REG_
    par-H4_  =   reg_.read-i8  PAR-H4-REG_
    par-H5_  =   reg_.read-i8  PAR-H5-REG_
    par-H6_  =   reg_.read-u8  PAR-H6-REG_
    par-H7_  =   reg_.read-i8  PAR-H7-REG_

    // Read gas calibration.
    par-GH1_ = reg_.read-i8     PAR-GH1-REG_
    par-GH2_ = reg_.read-i16-le PAR-GH2-REG_
    par-GH3_ = reg_.read-i8     PAR-GH3-REG_

    // Heater range calculation.
    res-heat-range_   = ((reg_.read-u8 RES-HEAT-RANGE-REG_) & 0b0011_0000 ) >> 4

    // Resistance correction factor.
    res-heat-val_ = reg_.read-i8 RES-HEAT-VAL-REG_

    // Range switching error.
    // According to BME680 data sheet RANGE_SW_ERR_REG_ should simply be read as is.
    // However, in the official Bosch driver only the four MSBs are used.
    // The below code implements the latter.
    range-sw-err_ = ((reg_.read-i8 RANGE-SW-ERR-REG_) & 0b1111_0000) >> 4

    // For debug purposes
    //print "par_T1_: $par_T1_"
    //print "par_T2_: $par_T2_"
    //print "par_T3_: $par_T3_"
    //print "par_P1_: $par_P1_"
    //print "par_P2_: $par_P2_"
    //print "par_P3_: $par_P3_"
    //print "par_P4_: $par_P4_"
    //print "par_P5_: $par_P5_"
    //print "par_P6_: $par_P6_"
    //print "par_P7_: $par_P7_"
    //print "par_P8_: $par_P8_"
    //print "par_P9_: $par_P9_"
    //print "par_P10_: $par_P10_"
    //print "par_H1_: $par_H1_"
    //print "par_H2_: $par_H2_"
    //print "par_H3_: $par_H3_"
    //print "par_H4_: $par_H4_"
    //print "par_H5_: $par_H5_"
    //print "par_H6_: $par_H6_"
    //print "par_H7_: $par_H7_"
    //print "par_G1_: $par_GH1_"
    //print "par_G2_: $par_GH2_"
    //print "par_G3_: $par_GH3_"
    //print "Heat Range: $res_heat_range_"
    //print "Heat Val: $res_heat_val_"
    //print "SW Error: $range_sw_err_"
