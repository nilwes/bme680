// Copyright C 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

// BME680 data sheet: https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme680-ds001.pdf

import binary
import serial.device as serial
import serial.registers as serial

I2C_ADDRESS     ::= 0x76
I2C_ADDRESS_ALT ::= 0x77

/**
Driver for the Bosch BME680 environmental sensor, using I2C.
*/
class bme680:
  // Chip ID address 
  static CHIP_ID_REG_                     ::=  0xD0

  // BME68X unique chip identifier
  static CHIP_ID_                         ::=  0x61
  
  // Soft reset command 
  static SOFT_RESET_CMD_                  ::=  0xB6

  //IIR Filter config
  IIR_FILTER_CONIFG_REG_                  ::=  0x75

  // 0th gas heater resistance 
  static RES_HEAT_REG0_                   ::=  0x5A

  // 0th gas heater resistance 
  static CTRL_GAS_REG_                    ::=  0x71
  
  // 0th gas heater wait 
  static GAS_WAIT_REG0_                   ::=  0x64
  
  // Humidity oversampling  
  static CTRL_HUM_REG_                    ::=  0x72
  
  // Temp, Pressure oversampling, and Force mode (Read sensors only on demand)
  static CTRL_MEAS_REG_                   ::=  0x74
  
  // Soft reset address
  static SOFT_RESET_REG_                  ::=  0xE0

  // Heater temp stability
  static HEAT_STAB_REG_                   ::=  0x2B // bit 4

  // Validity of gas measurement
  static GAS_VALID_REG_                   ::=  0x2B // bit 5

  //THP and gas measuring indicator bits
  static MEAS_STATUS_REG_                 ::=  0x1D
  
  // Data registers for THPG
  static TEMPDATA_REG_                    ::=  0x22 //Data stored in 3 consecutive bytes (20 bits)
  static HUMDATA_REG_                     ::=  0x25 //Data stored in 2 consecutive bytes (16 bits)
  static PRESSDATA_REG_                   ::=  0x1F //Data stored in 3 consecutive bytes (20 bits)
  static GASDATA_REG_                     ::=  0x2A //Data stored in 2 consecutive bytes (10 bits)

  // Calibration data registers
  static PAR_T1_REG_                      ::=  0xE9 // 16 bit
  static PAR_T2_REG_                      ::=  0x8A // 16 bit
  static PAR_T3_REG_                      ::=  0x8C //  8 bit
  static PAR_P1_REG_                      ::=  0x8E // 16 bit
  static PAR_P2_REG_                      ::=  0x90 // 16 bit
  static PAR_P3_REG_                      ::=  0x92 //  8 bit
  static PAR_P4_REG_                      ::=  0x94 // 16 bit
  static PAR_P5_REG_                      ::=  0x96 // 16 bit
  static PAR_P6_REG_                      ::=  0x99 //  8 bit
  static PAR_P7_REG_                      ::=  0x98 //  8 bit
  static PAR_P8_REG_                      ::=  0x9C // 16 bit
  static PAR_P9_REG_                      ::=  0x9E // 16 bit
  static PAR_P10_REG_                     ::=  0xA0 //  8 bit
  static PAR_H1_REG_LSB_                  ::=  0xE2  
  static PAR_H1_REG_MSB_                  ::=  0xE3
  static PAR_H2_REG_LSB_                  ::=  0xE2 
  static PAR_H2_REG_MSB_                  ::=  0xE1
  static PAR_H3_REG_                      ::=  0xE4 //  8 bit
  static PAR_H4_REG_                      ::=  0xE5 //  8 bit
  static PAR_H5_REG_                      ::=  0xE6 //  8 bit
  static PAR_H6_REG_                      ::=  0xE7 //  8 bit
  static PAR_H7_REG_                      ::=  0xE8 //  8 bit
  static PAR_GH1_REG_                     ::=  0xED // 8 bit
  static PAR_GH2_REG_                     ::=  0xEB // 16 bit
  static PAR_GH3_REG_                     ::=  0xEE // 8 bit
  static RES_HEAT_RANGE_REG_              ::=  0x02 // 8 bit
  static RES_HEAT_VAL_REG_                ::=  0x00 // 8 bit, signed
  static RANGE_SW_ERR_REG_                ::=  0x04

  reg_/serial.Registers ::= ?

  // Calibration data variables
  par_T1_          := null
  par_T2_          := null
  par_T3_          := null
  par_P1_          := null
  par_P2_          := null
  par_P3_          := null
  par_P4_          := null
  par_P5_          := null
  par_P6_          := null
  par_P7_          := null
  par_P8_          := null
  par_P9_          := null
  par_P10_         := null
  par_H1_          := null
  par_H2_          := null
  par_H3_          := null
  par_H4_          := null
  par_H5_          := null
  par_H6_          := null
  par_H7_          := null
  par_GH1_         := null
  par_GH2_         := null
  par_GH3_         := null
  res_heat_range_  := null
  res_heat_val_    := null
  range_sw_err_    := null

  temp_comp_ := 0
  t_fine_    := 0

  //ADC Ranges used for gas resistance calculations
  const_array1 ::= [1, 1, 1, 1, 1, 0.99, 1, 0.992, 1, 1, 0.998, 0.995, 1, 0.99, 1, 1]
  const_array2 ::= [8000000, 4000000, 2000000, 1000000, 499500.4995,
                    248262.1648, 125000, 63004.03226, 31281.28128, 15625,
                    7812.5, 3906.25, 1953.125, 976.5625, 488.28125, 244.140625]
  
  constructor dev/serial.Device:
    reg_ = dev.registers
    rslt := 0

    // Reset device
    reg_.write_u8 SOFT_RESET_REG_ SOFT_RESET_CMD_
    sleep --ms=5 
    
    // Check chip ID
    rslt = reg_.read_u8 CHIP_ID_REG_
    if rslt != CHIP_ID_: throw "INVALID_CHIP"

    read_calibration_data_

    // Sleep mode. No measurement until we say so.

    // 1x oversampling hum
    reg_.write_u8 CTRL_HUM_REG_ 0b00_000_001

    // 2x oversampling temp. 16x oversampling press.
    reg_.write_u8 CTRL_MEAS_REG_ 0b010_101_00

    // No IIR filter
    reg_.write_u8 IIR_FILTER_CONIFG_REG_ 0b000_000_00

    //Set run_gas and choose heater resistance at 0th position
    reg_.write_u8 CTRL_GAS_REG_ 0b000_1_0000

    // gas_wait to ~100ms
    reg_.write_u8 GAS_WAIT_REG0_ 0x59 
    
    // heater resistance calculation and storage
    res_heat := calculate_res_heat
    reg_.write_u8 RES_HEAT_REG0_ res_heat

  /**
  Reads the temperature and returns it in degrees Celsius.
  */
  read_temperature -> float:
    measure_
    return temp_comp_ 

  /**
  Reads the relative humidity and returns it as a percent in the range `0.0 - 100.0`.
  */
  read_humidity -> float:
    reg_.write_u8 CTRL_HUM_REG_ 0b0000_0001 // 1x oversampling
    measure_
    hum_adc  := reg_.read_u16_be HUMDATA_REG_

    hvar1 := hum_adc - ((par_H1_ * 16.0) + ((par_H3_ / 2.0) * temp_comp_))
    hvar2 := hvar1 * ((par_H2_ / 262144.0) * (1.0 + ((par_H4_ / 16384.0) *
      temp_comp_) + ((par_H5_ / 1048576.0) * temp_comp_ * temp_comp_)))
    hvar3 := par_H6_ / 16384.0
    hvar4 := par_H7_ / 2097152.0
    hum_comp := hvar2 + ((hvar3 + (hvar4 * temp_comp_)) * hvar2 * hvar2)

    return hum_comp

  /**
  Reads the barometric pressure and returns it in Pascals.
  */
  read_pressure -> float:

      measure_
      press_adc := reg_.read_u24_be PRESSDATA_REG_
      press_adc >>= 4

      var1 := ((t_fine_ / 2.0) - 64000.0)
      var2 := var1 * var1 * ((par_P6_) / (131072.0))
      var2 = var2 + (var1 * (par_P5_) * 2.0)
      var2 = (var2 / 4.0) + ((par_P4_) * 65536.0)
      var1 = ((((par_P3_ * var1 * var1) / 16384.0) + (par_P2_ * var1)) / 524288.0)
      var1 = ((1.0 + (var1 / 32768.0)) * (par_P1_))
      calc_pres := (1048576.0 - (press_adc))

      // Avoid exception caused by division by zero
      if var1 == 0: return 0.0

      calc_pres = (((calc_pres - (var2 / 4096.0)) * 6250.0) / var1)
      var1 = ((par_P9_) * calc_pres * calc_pres) / 2147483648.0
      var2 = calc_pres * ((par_P8_) / 32768.0)
      var3 := ((calc_pres / 256.0) * (calc_pres / 256.0) * (calc_pres / 256.0) * (par_P10_ / 131072.0))
      press_comp := (calc_pres + (var1 + var2 + var3 + (par_P7_ * 128.0)) / 16.0)

      return press_comp + 900.0 // 9 -> Calibration to known QNH

  /**
  Reads the gas resistance and returns it in Ohm.
  */
  read_gas -> float:
    reg_.write_u8 CTRL_MEAS_REG_ 0b010_101_01 // Trigger force mode gas measurement
   
    wait_for_gas_measurement_

    if ((reg_.read_u8 HEAT_STAB_REG_) & 0b00_1_00000)  == 0:
      print "No valid gas measurement"
      return -1.0

    if ((reg_.read_u8 HEAT_STAB_REG_) & 0b000_1_0000)  == 0:
      print "Heater temperature not stable"
      return -1.0

    gas_adc := reg_.read_u16_be GASDATA_REG_
    gas_adc >>= 6

    gas_range := (reg_.read_u8 HEAT_STAB_REG_) & 0b0000_1111

    // Adopted from https://github.com/adafruit/Adafruit_BME680/blob/master/bme68x.c
    var1 := (1340.0 + (5.0 * range_sw_err_))
    var2 := (var1) * (1.0 + const_array1[gas_range] / 100.0)
    var3 := 1.0 + (const_array2[gas_range] / 100.0)
    gas_res := 1.0 / (var3 * (0.000000125) * gas_range * (((gas_adc - 512.0) / var2) + 1.0))

    return gas_res
  /**
  Calculates the goal gas heater plat resistance and returns it.
  */
  calculate_res_heat -> int:
    plate_temp ::= 300 // Gas sensor will heat to this temp in Celsius. Mapped below to a resistance value.
    amb_temp := read_temperature // Get ambient temperature. Needed for calculations below.

    var1 := (par_GH1_ / 16.0) + 49.0
    var2 := ((par_GH2_ / 32768.0) * 0.0005) + 0.00235
    var3 := (par_GH3_ / 1024.0)
    var4 := var1 * (1.0 + (var2 * plate_temp))
    var5 := var4 + (var3 * amb_temp)
    res_heat := (3.4 * ((var5 * (4.0 / (4.0 + res_heat_range_)) * 
      (1.0 / (1.0 + (res_heat_val_ * 0.002)))) - 25)).to_int
    
    return res_heat
  /**
  Performs sensor readout into data registers.
  */
  measure_:
    reg_.write_u8 CTRL_MEAS_REG_ 0b001_001_01
    sleep --ms=8
    wait_for_measurement_

    temp_adc := reg_.read_u24_be TEMPDATA_REG_

    temp_adc >>= 4

    var1 := ((temp_adc / 16384.0) - (par_T1_ / 1024.0)) * par_T2_
    var2 := (((temp_adc / 131072.0) - (par_T1_ / 8192.0)) *
      (temp_adc / 131072.0) - (par_T1_ / 8192.0)) * 
      (par_T3_ * 16.0)
    t_fine_ = var1 + var2
    temp_comp_ = t_fine_ / 5120.0
    
  /**
  Checks whether THP measurement is done.
  */
  wait_for_measurement_:
    16.repeat:
      val := reg_.read_u8 MEAS_STATUS_REG_
      if val & 0b0010_0000 == 0:
        return
      sleep --ms=it + 1  // Back off slowly.
    throw "BME280: Unable to measure THP"
  /**
  Checks whether gas measurement is done.
  */
  wait_for_gas_measurement_:
    16.repeat:
      val := reg_.read_u8 MEAS_STATUS_REG_
      if val & 0b0100_0000 == 0: 
        return
      sleep --ms=it + 1  // Back off slowly.
    throw "BME680: Unable to measure gas"

  /**
  Reads calibration data stored in sensor memory.
  */
  read_calibration_data_:
    // Read temperature calibration
    par_T1_ = reg_.read_u16_le PAR_T1_REG_
    par_T2_ = reg_.read_i16_le PAR_T2_REG_
    par_T3_ = reg_.read_i8 PAR_T3_REG_
    
    // Read pressure calibration
    par_P1_  = reg_.read_u16_le  PAR_P1_REG_
    par_P2_  = reg_.read_i16_le  PAR_P2_REG_
    par_P3_  = reg_.read_i8      PAR_P3_REG_ 
    par_P4_  = reg_.read_i16_le  PAR_P4_REG_
    par_P5_  = reg_.read_i16_le  PAR_P5_REG_
    par_P6_  = reg_.read_i8      PAR_P6_REG_
    par_P7_  = reg_.read_i8      PAR_P7_REG_
    par_P8_  = reg_.read_i16_le  PAR_P8_REG_
    par_P9_  = reg_.read_i16_le  PAR_P9_REG_
    par_P10_ = reg_.read_i8     PAR_P10_REG_

    // Read humidity calibration
    par_H1_  = ((reg_.read_u8  PAR_H1_REG_MSB_) << 4) | ((reg_.read_u8 PAR_H1_REG_LSB_) & 0b00001111)
    par_H2_  = ((reg_.read_u8  PAR_H2_REG_MSB_) << 4) | ((reg_.read_u8 PAR_H2_REG_LSB_) >> 4);
    par_H3_  =   reg_.read_i8  PAR_H3_REG_
    par_H4_  =   reg_.read_i8  PAR_H4_REG_   
    par_H5_  =   reg_.read_i8  PAR_H5_REG_     
    par_H6_  =   reg_.read_u8  PAR_H6_REG_
    par_H7_  =   reg_.read_i8  PAR_H7_REG_

    // Read gas calibration
    par_GH1_ = reg_.read_i8     PAR_GH1_REG_
    par_GH2_ = reg_.read_i16_le PAR_GH2_REG_
    par_GH3_ = reg_.read_i8     PAR_GH3_REG_

    // Heater range calculation
    res_heat_range_   = ((reg_.read_u8 RES_HEAT_RANGE_REG_) & 0b0011_0000 ) >> 4

    // Resistance correction factor
    res_heat_val_ = reg_.read_i8 RES_HEAT_VAL_REG_

    // Range switching error
    // According to BME680 data sheet RANGE_SW_ERR_REG_ should simply be read as is.
    // However, in the official Bosch driver only the four MSBs are used. 
    // The below code implements the latter. 
    range_sw_err_ = ((reg_.read_i8 RANGE_SW_ERR_REG_) & 0b1111_0000) >> 4
    
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
