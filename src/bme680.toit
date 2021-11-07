// Copyright C 2021 Toitware ApS. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be found
// in the LICENSE file.

import binary
import serial.device as serial
import serial.registers as serial

I2C_ADDRESS     ::= 0x76
I2C_ADDRESS_ALT ::= 0x77

/**
Driver for the Bosch BME680 environmental sensor, using either I2C or SPI.
*/
class bme680:
  static REGISTER_CHIPID_                  ::= 0xD0
  /* BME68X unique chip identifier */
  static CHIP_ID_                          ::= 0x61
  
  /* Period for a soft reset */
  static PERIOD_RESET_                     ::= 10000
  
  /* BME68X lower I2C address */
  static I2C_ADDR_LOW_                     ::= 0x76
  
  /* BME68X higher I2C address */
  static I2C_ADDR_HIGH_                    ::= 0x77
  
  /* Soft reset command */
  static SOFT_RESET_CMD_                   ::= 0xB6
  
  /* Return code definitions */
  /* Success */
  static OK_                               ::= 0
  
  /* Errors */
  /* Null pointer passed */
  static E_NULL_PTR                        ::= -1
  
  /* Communication failure */
  static E_COM_FAIL                        ::= -2
  
  /* Sensor not found */
  static E_DEV_NOT_FOUND                   ::= -3
  
  /* Incorrect length parameter */
  static E_INVALID_LENGTH                 ::=  -4
  
  /* Self test fail error */
  static E_SELF_TEST                      ::=  -5
  
  /* Warnings */
  /* Define a valid operation mode */
  static W_DEFINE_OP_MODE                 ::=  1
  
  /* No new data was found */
  static W_NO_NEW_DATA                    ::=  2
  
  /* Define the shared heating duration */
  static W_DEFINE_SHD_HEATR_DUR           ::=  3
  
  /* Information - only available via dev.info_msg */
  static I_PARAM_CORR                      ::= 1
  
  /* Register map addresses in I2C */
  /* Register for 3rd group of coefficients */
  static REG_COEFF3                       ::=  0x00
  
  /* 0th Field address*/
  static REG_FIELD0                       ::=  0x1D
  
  /* 0th Current DAC address*/
  static REG_IDAC_HEAT0                   ::=  0x50
  
  /* 0th Res heat address */
  static REG_RES_HEAT0                    ::=  0x5A
  
  /* 0th Gas wait address */
  static REG_GAS_WAIT0                    ::=  0x64
  
  /* Shared heating duration address */
  static REG_SHD_HEATR_DUR                ::=  0x6E
  
  /* CTRL_GAS_0 address */
  static REG_CTRL_GAS_0                   ::=  0x70
  
  /* CTRL_GAS_1 address */
  static REG_CTRL_GAS_1                   ::=  0x71
  
  /* CTRL_HUM address */
  static REG_CTRL_HUM_                     ::=  0x72
  
  /* CTRL_MEAS address */
  static REG_CTRL_MEAS_                    ::=  0x74
  
  /* CONFIG address */
  static REG_CONFIG_                       ::=  0x75
  
  /* MEM_PAGE address */
  static REG_MEM_PAGE                     ::=  0xF3
  
  /* Unique ID address */
  static REG_UNIQUE_ID                    ::=  0x83
  
  /* Register for 1st group of coefficients */
  static REG_COEFF1                       ::=  0x8a
  
  /* Chip ID address */
  static REG_CHIP_ID                      ::=  0xD0
  
  /* Soft reset address */
  static REG_SOFT_RESET_                   ::=  0xE0
  
  /* Register for 2nd group of coefficients */
  static REG_COEFF2                        ::= 0xE1
  
  /* Variant ID Register */
  static REG_VARIANT_ID                    ::= 0xF0
  
  /* Enable/Disable macros */
  
  /* Enable */
  static ENABLE                            ::= 0x01
  
  /* Disable */
  static DISABLE                           ::= 0x00
  
  /* Variant ID macros */
  
  /* Low Gas variant */
  static VARIANT_GAS_LOW                   ::= 0x00
  
  /* High Gas variant */
  static VARIANT_GAS_HIGH                  ::= 0x01
  
  /* Oversampling setting macros */
  
  /* Switch off measurement */
  static OS_NONE                          ::=  0
  
  /* Perform 1 measurement */
  static OS_1X                            ::=  1
  
  /* Perform 2 measurements */
  static OS_2X                            ::=  2
  
  /* Perform 4 measurements */
  static OS_4X                           ::=   3
  
  /* Perform 8 measurements */
  static OS_8X                            ::=  4
  
  /* Perform 16 measurements */
  static OS_16X                           ::=  5
  
  /* IIR Filter settings */
  
  /* Switch off the filter */
  static FILTER_OFF                       ::=  0
  
  /* Filter coefficient of 2 */
  static FILTER_SIZE_1                    ::=  1
  
  /* Filter coefficient of 4 */
  static FILTER_SIZE_3                    ::=  2
  
  /* Filter coefficient of 8 */
  static FILTER_SIZE_7                    ::=  3
  
  /* Filter coefficient of 16 */
  static FILTER_SIZE_15                   ::=     4
  
  /* Filter coefficient of 32 */
  static FILTER_SIZE_31                   ::=     5
  
  /* Filter coefficient of 64 */
  static FILTER_SIZE_63                   ::=     6
  
  /* Filter coefficient of 128 */
  static FILTER_SIZE_127                  ::=     7
  
  /* ODR/Standby time macros */
  
  /* Standby time of 0.59ms */
  static ODR_0_59_MS                    ::=    0
  
  /* Standby time of 62.5ms */
  static ODR_62_5_MS                    ::=    1
  
  /* Standby time of 125ms */
  static ODR_125_MS                     ::=    2
  
  /* Standby time of 250ms */
  static ODR_250_MS                     ::=    3
  
  /* Standby time of 500ms */
  static ODR_500_MS                     ::=    4
  
  /* Standby time of 1s */
  static ODR_1000_MS                    ::=    5
  
  /* Standby time of 10ms */
  static ODR_10_MS                      ::=    6
  
  /* Standby time of 20ms */
  static ODR_20_MS                      ::=    7
  
  /* No standby time */
  static ODR_NONE                       ::=   8
  
  /* Operating mode macros */
  
  /* Sleep operation mode */
  static SLEEP_MODE                     ::=   0x00
  
  /* Forced operation mode */
  static FORCED_MODE                    ::=   0x01
  
  /* Parallel operation mode */
  static PARALLEL_MODE                  ::=  0x02
  
  /* Sequential operation mode */
  static SEQUENTIAL_MODE                ::=  0x03
  
  /* SPI page macros */
  
  /* SPI memory page 0 */
  static MEM_PAGE0                      ::=  0x10
  
  /* SPI memory page 1 */
  static MEM_PAGE1                      ::=  0x00
  
  /* Coefficient index macros */
  
  /* Length for all coefficients */
  static LEN_COEFF_ALL                  ::=  42
  
  /* Length for 1st group of coefficients */
  static LEN_COEFF1                        ::= 23
  
  /* Length for 2nd group of coefficients */
  static LEN_COEFF2                        ::= 14
  
  /* Length for 3rd group of coefficients */
  static LEN_COEFF3                       ::=  5
  
  /* Length of the field */
  static LEN_FIELD                        ::=  17
  
  /* Length between two fields */
  static LEN_FIELD_OFFSET                 ::=  17
  
  /* Length of the configuration register */
  static LEN_CONFIG                       ::=  5
  
  /* Length of the interleaved buffer */
  static LEN_INTERLEAVE_BUFF              ::=  20
  
  /* Coefficient index macros */
  
  /* Coefficient T2 LSB position */
  static IDX_T2_LSB                       ::=  0
  
  /* Coefficient T2 MSB position */
  static IDX_T2_MSB                       ::=  1
  
  /* Coefficient T3 position */
  static IDX_T3                           ::=  2
  
  /* Coefficient P1 LSB position */
  static IDX_P1_LSB                       ::=  4
  
  /* Coefficient P1 MSB position */
  static IDX_P1_MSB                       ::=  5
  
  /* Coefficient P2 LSB position */
  static IDX_P2_LSB                       ::=  6
  
  /* Coefficient P2 MSB position */
  static IDX_P2_MSB                       ::=  7
  
  /* Coefficient P3 position */
  static IDX_P3                           ::=  8
  
  /* Coefficient P4 LSB position */
  static IDX_P4_LSB                       ::=  10
  
  /* Coefficient P4 MSB position */
  static IDX_P4_MSB                       ::=  11
  
  /* Coefficient P5 LSB position */
  static IDX_P5_LSB                       ::=  12
  
  /* Coefficient P5 MSB position */
  static IDX_P5_MSB                       ::=  13
  
  /* Coefficient P7 position */
  static IDX_P7                           ::=  14
  
  /* Coefficient P6 position */
  static IDX_P6                           ::=  15
  
  /* Coefficient P8 LSB position */
  static IDX_P8_LSB                       ::=  18
  
  /* Coefficient P8 MSB position */
  static IDX_P8_MSB                       ::=   19
  
  /* Coefficient P9 LSB position */
  static IDX_P9_LSB                       ::=  20
  
  /* Coefficient P9 MSB position */
  static IDX_P9_MSB                       ::=   21
  
  /* Coefficient P10 position */
  static IDX_P10                          ::=   22
  
  /* Coefficient H2 MSB position */
  static IDX_H2_MSB                       ::=  23
  
  /* Coefficient H2 LSB position */
  static IDX_H2_LSB                       ::=  24
  
  /* Coefficient H1 LSB position */
  static IDX_H1_LSB                       ::=  24
  
  /* Coefficient H1 MSB position */
  static IDX_H1_MSB                       ::=    25
  
  /* Coefficient H3 position */
  static IDX_H3                           ::=   26
   
  /* Coefficient H4 position */ 
  static IDX_H4                           ::=   27
   
  /* Coefficient H5 position */ 
  static IDX_H5                           ::=   28
   
  /* Coefficient H6 position */ 
  static IDX_H6                           ::=   29
   
  /* Coefficient H7 position */ 
  static IDX_H7                           ::=   30
   
  /* Coefficient T1 LSB position */ 
  static IDX_T1_LSB                       ::=   31
   
  /* Coefficient T1 MSB position */ 
  static IDX_T1_MSB                       ::=   32
   
  /* Coefficient GH2 LSB position */ 
  static IDX_GH2_LSB                      ::=   33
   
  /* Coefficient GH2 MSB position */ 
  static IDX_GH2_MSB                      ::=   34
  
  /* Coefficient GH1 position */
  static IDX_GH1                         ::=   35
  
  /* Coefficient GH3 position */
  static IDX_GH3                         ::=   36
  
  /* Coefficient res heat value position */
  static IDX_RES_HEAT_VAL                ::=   37
  
  /* Coefficient res heat range position */
  static IDX_RES_HEAT_RANGE              ::=   39
  
  /* Coefficient range switching error position */
  static IDX_RANGE_SW_ERR                ::=   41
  
  /* Gas measurement macros */
  
  /* Disable gas measurement */
  static DISABLE_GAS_MEAS                ::=   0x00
  
  /* Enable gas measurement low */
  static ENABLE_GAS_MEAS_L               :=   0x01
  
  /* Enable gas measurement high */
  static ENABLE_GAS_MEAS_H               :=   0x02
  
  /* Heater control macros */
  
  /* Enable heater */
  static ENABLE_HEATER                   ::=  0x00
  
  /* Disable heater */
  static DISABLE_HEATER                  ::=  0x01

  /* 0 degree Celsius */
  static MIN_TEMPERATURE                 ::=  0
  
  /* 60 degree Celsius */
  static MAX_TEMPERATURE                 ::=  60
  
  /* 900 hecto Pascals */
  static MIN_PRESSURE                    ::=  90000
  
  /* 1100 hecto Pascals */
  static MAX_PRESSURE                    ::=  110000
  
  /* 20% relative humidity */
  static MIN_HUMIDITY                    ::=  20
  
  /* 80% relative humidity*/
  static MAX_HUMIDITY                    ::=  80
  
  static HEATR_DUR1                      ::=  1000
  static HEATR_DUR2                      ::=  2000
  static HEATR_DUR1_DELAY                ::=  1000000
  static HEATR_DUR2_DELAY                ::=  2000000
  static N_MEAS                          ::=  6
  static LOW_TEMP                        ::=  150
  static HIGH_TEMP                       ::=  350
  
  /* Mask macros */
  /* Mask for number of conversions */
  static NBCONV_MSK                       ::=  0X0f
  
  /* Mask for IIR filter */
  static FILTER_MSK                       ::=  0X1c
  
  /* Mask for ODR[3] */
  static ODR3_MSK                         ::=  0x80
  
  /* Mask for ODR[2:0] */
  static ODR20_MSK                        ::=  0xe0
  
  /* Mask for temperature oversampling */
  static OST_MSK                          ::=  0Xe0
  
  /* Mask for pressure oversampling */
  static OSP_MSK                          ::=  0X1c
  
  /* Mask for humidity oversampling */
  static OSH_MSK                          ::=  0X07
  
  /* Mask for heater control */
  static HCTRL_MSK                        ::=  0x08
  
  /* Mask for run gas */
  static RUN_GAS_MSK                      ::=  0x30
  
  /* Mask for operation mode */
  static MODE_MSK                         ::=  0x03
  
  /* Mask for res heat range */
  static RHRANGE_MSK                      ::=  0x30
  
  /* Mask for range switching error */
  static RSERROR_MSK                      ::=  0xf0
  
  /* Mask for new data */
  static NEW_DATA_MSK                     ::=  0x80
  
  /* Mask for gas index */
  static GAS_INDEX_MSK                    ::=  0x0f
  
  /* Mask for gas range */
  static GAS_RANGE_MSK                    ::=  0x0f
  
  /* Mask for gas measurement valid */
  static GASM_VALID_MSK                   ::=  0x20
  
  /* Mask for heater stability */
  static HEAT_STAB_MSK                    ::=  0x10
  
  /* Mask for SPI memory page */
  static MEM_PAGE_MSK                     ::=  0x10
  
  /* Mask for reading a register in SPI */
  static SPI_RD_MSK                       ::=  0x80
  
  /* Mask for writing a register in SPI */
  static SPI_WR_MSK                       ::=  0x7f
  
  /* Mask for the H1 calibration coefficient */
  static BIT_H1_DATA_MSK                   ::= 0x0f
  
  /* Position macros */
  
  /* Filter bit position */
  static FILTER_POS                        ::= 2
  
  /* Temperature oversampling bit position */
  static OST_POS                          ::=  5
  
  /* Pressure oversampling bit position */
  static OSP_POS                          ::=  2
  
  /* ODR[3] bit position */
  static ODR3_POS                         ::=  7
  
  /* ODR[2:0] bit position */
  static ODR20_POS                        ::=  5
  
  /* Run gas bit position */
  static RUN_GAS_POS                      ::=  4
  
  /* Heater control bit position */
  static HCTRL_POS                        ::=  3

  static TEMPDATA_REG_                    ::= 0x22 //Data stored in 3 consecutive bytes
  static HUMDATA_REG_                     ::= 0x25 //Data stored in 2 consecutive bytes
  static PRESSDATA_REG_                   ::= 0x1F //Data stored in 3 consecutive bytes
 
  static PAR_T1_REG_                      ::= 0xE9 // 16 bit
  static PAR_T2_REG_                      ::= 0x8A // 16 bit
  static PAR_T3_REG_                      ::= 0x8C //  8 bit

  static PAR_P1_REG_                      ::= 0x8E // 16 bit
  static PAR_P2_REG_                      ::= 0x90 // 16 bit
  static PAR_P3_REG_                      ::= 0x92 //  8 bit
  static PAR_P4_REG_                      ::= 0x94 // 16 bit
  static PAR_P5_REG_                      ::= 0x96 // 16 bit
  static PAR_P6_REG_                      ::= 0x99 //  8 bit
  static PAR_P7_REG_                      ::= 0x98 //  8 bit
  static PAR_P8_REG_                      ::= 0x9C // 16 bit
  static PAR_P9_REG_                      ::= 0x9E // 16 bit
  static PAR_P10_REG_                     ::= 0xA0 //  8 bit

  static PAR_H1_REG_LSB_                  ::= 0xE2  
  static PAR_H1_REG_MSB_                  ::= 0xE3
  static PAR_H2_REG_LSB_                  ::= 0xE2 
  static PAR_H2_REG_MSB_                  ::= 0xE1
  static PAR_H3_REG_                      ::= 0xE4 //  8 bit
  static PAR_H4_REG_                      ::= 0xE5 //  8 bit
  static PAR_H5_REG_                      ::= 0xE6 //  8 bit
  static PAR_H6_REG_                      ::= 0xE7 //  8 bit
  static PAR_H7_REG_                      ::= 0xE8 //  8 bit

  static PAR_GH1_REG_                     ::= 0xED // 8 bit
  static PAR_GH2_REG_                     ::= 0xEB // 16 bit
  static PAR_GH3_REG_                     ::= 0xEE // 8 bit


  static RES_HEAT_RANGE_REG_              ::= 0x02 // 8 bit
  static RES_HEAT_VAL_REG_                ::= 0x00 // 8 bit, signed

  static RANGE_SW_ERR_REG_                ::= 0x04

  reg_/serial.Registers ::= ?

  par_T1_  := null
  par_T2_  := null
  par_T3_  := null
 
  par_P1_  := null
  par_P2_  := null
  par_P3_  := null
  par_P4_  := null
  par_P5_  := null
  par_P6_  := null
  par_P7_  := null
  par_P8_  := null
  par_P9_  := null
  par_P10_  := null
 
 
  par_H1_  := null
  par_H2_  := null
  par_H3_  := null
  par_H4_  := null
  par_H5_  := null
  par_H6_  := null
  par_H7_  := null

  par_GH1_  := null
  par_GH2_  := null
  par_GH3_  := null

  res_heat_range_  := null
  res_heat_val_     := null
  range_sw_err_     := null

  temp_comp_ := 0
  t_fine_    := 0

  constructor dev/serial.Device:
    reg_ = dev.registers
    rslt := 0

    // Reset device
    reg_.write_u8 REG_SOFT_RESET_ SOFT_RESET_CMD_
    sleep --ms=5 
    
    // Check chip ID
    rslt = reg_.read_u8 REG_CHIP_ID
    if rslt != CHIP_ID_: throw "INVALID_CHIP"
    //print "Chip ID: $rslt"

    //rslt = reg_.read_u8 REG_VARIANT_ID
    //print  "Chip Variant: $rslt"

    read_calibration_data_

    // Sleep mode. No measurement until we say so.
    // Also no oversampling on temp and hum.
    reg_.write_u8 REG_CTRL_MEAS_ 0b000_000_00
    // No IIR filter
    reg_.write_u8 REG_CONFIG_    0b000_000_0_0


  read_temperature -> float:
    measure_
    return temp_comp_ 


  read_humidity -> float:
    reg_.write_u8 REG_CTRL_HUM_  0b0000_0001 // 1x oversampling
    measure_
    hum_adc  := reg_.read_u16_be HUMDATA_REG_

    hvar1 := hum_adc - ((par_H1_ * 16.0) + ((par_H3_ / 2.0) * temp_comp_))
    hvar2 := hvar1 * ((par_H2_ / 262144.0) * (1.0 + ((par_H4_ / 16384.0) *
      temp_comp_) + ((par_H5_ / 1048576.0) * temp_comp_ * temp_comp_)))
    hvar3 := par_H6_ / 16384.0
    hvar4 := par_H7_ / 2097152.0
    hum_comp := hvar2 + ((hvar3 + (hvar4 * temp_comp_)) * hvar2 * hvar2)

    return hum_comp


  read_pressure -> float:
      measure_
      press_adc := reg_.read_u24_be PRESSDATA_REG_
      press_adc >>= 4

      var1 := ((t_fine_ / 2.0) - 64000.0);
      var2 := var1 * var1 * ((par_P6_) / (131072.0));
      var2 = var2 + (var1 * (par_P5_) * 2.0);
      var2 = (var2 / 4.0) + ((par_P4_) * 65536.0);
      var1 = ((((par_P3_ * var1 * var1) / 16384.0) + (par_P2_ * var1)) / 524288.0);
      var1 = ((1.0 + (var1 / 32768.0)) * (par_P1_));
      calc_pres := (1048576.0 - (press_adc));

      // Avoid exception caused by division by zero
      if var1 == 0: return 0.0

      calc_pres = (((calc_pres - (var2 / 4096.0)) * 6250.0) / var1);
      var1 = ((par_P9_) * calc_pres * calc_pres) / 2147483648.0;
      var2 = calc_pres * ((par_P8_) / 32768.0);
      var3 := ((calc_pres / 256.0) * (calc_pres / 256.0) * (calc_pres / 256.0) * (par_P10_ / 131072.0));
      press_comp := (calc_pres + (var1 + var2 + var3 + (par_P7_ * 128.0)) / 16.0);

      return press_comp + 10.0


  measure_:
    reg_.write_u8 REG_CTRL_MEAS_ 0b001_001_01
    sleep --ms=8
    temp_adc := reg_.read_u24_be TEMPDATA_REG_

    temp_adc >>= 4

    var1 := ((temp_adc / 16384.0) - (par_T1_ / 1024.0)) * par_T2_
    var2 := (((temp_adc / 131072.0) - (par_T1_ / 8192.0)) *
      (temp_adc / 131072.0) - (par_T1_ / 8192.0)) * 
      (par_T3_ * 16.0)
    t_fine_ = var1 + var2
    temp_comp_ = t_fine_ / 5120.0
    

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
    par_H1_ = ((reg_.read_u8  PAR_H1_REG_MSB_) << 4) | ((reg_.read_u8 PAR_H1_REG_LSB_) & 0b00001111)
    par_H2_ = ((reg_.read_u8  PAR_H2_REG_MSB_) << 4) | ((reg_.read_u8 PAR_H2_REG_LSB_) >> 4);
    par_H3_ =   reg_.read_i8  PAR_H3_REG_
    par_H4_ =   reg_.read_i8  PAR_H4_REG_   
    par_H5_ =   reg_.read_i8  PAR_H5_REG_     
    par_H6_ =   reg_.read_u8  PAR_H6_REG_
    par_H7_ =   reg_.read_i8  PAR_H7_REG_

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