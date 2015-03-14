!***********************************************************************
! Read and makes available climate data (tmin, tmax, precip, potential
! solar radiation, potential evapotranspieration) and/or transpiration
! on, by HRU from files pre-processed Data Files available for other
! PRMS modules
!***********************************************************************
      MODULE PRMS_CLIMATE_HRU
        USE PRMS_MODULE, ONLY: MAXFILE_LENGTH
        ! Local Variables
        INTEGER, SAVE :: Precip_unit, Tmax_unit, Tmin_unit, Et_unit, Swrad_unit, Transp_unit
        INTEGER, SAVE :: Humidity_unit, Windspeed_unit
        CHARACTER(LEN=11), SAVE :: MODNAME
        ! Control Parameters
        CHARACTER(LEN=MAXFILE_LENGTH), SAVE :: Tmin_day, Tmax_day, Precip_day, Potet_day, Swrad_day, Transp_day
        CHARACTER(LEN=MAXFILE_LENGTH), SAVE :: Humidity_day, Windspeed_day
        INTEGER, SAVE :: Cbh_check_flag, Cbh_binary_flag
        ! Declared Variables
        DOUBLE PRECISION, SAVE :: Basin_humidity, Basin_windspeed
        REAL, ALLOCATABLE :: Humidity_hru(:), Windspeed_hru(:)
        ! Declared Parameters
        INTEGER, SAVE :: Adj_by_hru
        INTEGER, SAVE, ALLOCATABLE :: Hru_subbasin(:)
        REAL, SAVE, ALLOCATABLE :: Rain_sub_adj(:, :), Snow_sub_adj(:, :)
        REAL, SAVE, ALLOCATABLE :: Rain_cbh_adj(:, :), Snow_cbh_adj(:, :), Potet_cbh_adj(:, :)
        REAL, SAVE, ALLOCATABLE :: Tmax_cbh_adj(:), Tmin_cbh_adj(:)
      END MODULE PRMS_CLIMATE_HRU

      INTEGER FUNCTION climate_hru()
      USE PRMS_CLIMATE_HRU
      USE PRMS_MODULE, ONLY: Process, Nhru, Climate_transp_flag, Orad_flag, Model, Nsub, Subbasin_flag, &
     &    Climate_precip_flag, Climate_temp_flag, Climate_potet_flag, Climate_swrad_flag, &
     &    Start_year, Start_month, Start_day, Humidity_cbh_flag, Windspeed_cbh_flag
      USE PRMS_BASIN, ONLY: Active_hrus, Hru_route_order, Hru_area, Basin_area_inv, NEARZERO, MM2INCH
      USE PRMS_CLIMATEVARS, ONLY: Solrad_tmax, Solrad_tmin, Basin_temp, &
     &    Basin_tmax, Basin_tmin, Tmaxf, Tminf, Tminc, Tmaxc, Tavgf, &
     &    Tavgc, Hru_ppt, Hru_rain, Hru_snow, Prmx, Pptmix, Newsnow, &
     &    Precip_units, Tmax_allrain_f, Adjmix_rain, &
     &    Basin_ppt, Basin_potet, Potet, Basin_snow, Basin_rain, &
     &    Basin_horad, Orad, Swrad, Basin_potsw, Basin_obs_ppt, &
     &    Transp_on, Basin_transp_on, Tmax_allsnow_f
      USE PRMS_SET_TIME, ONLY: Nowmonth, Jday
      USE PRMS_SOLTAB, ONLY: Soltab_basinpotsw, Hru_cossl, Soltab_potsw
      IMPLICIT NONE
! Functions
      INTRINSIC ABS
      INTEGER, EXTERNAL :: declparam, control_integer, getparam, control_string, declvar
      EXTERNAL :: read_error, precip_form, temp_set, find_header_end, find_current_time
      EXTERNAL :: read_cbh_date, check_cbh_value, check_cbh_intvalue, print_module
! Local Variables
      INTEGER :: yr, mo, dy, i, hr, mn, sec, jj, ierr, istop, missing, j, k, ios
      REAL :: tmax_hru, tmin_hru, ppt, harea, adjmix, allrain
      CHARACTER(LEN=80), SAVE :: Version_climate_hru
!***********************************************************************
      climate_hru = 0
      ierr = 0
      IF ( Process(:3)=='run' ) THEN
        IF ( Climate_temp_flag==1 ) THEN
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Tmax_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Tmaxf(i), i=1,Nhru)
          ELSE
            READ ( Tmax_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Tmaxf(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Tmaxf', ios, ierr)
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Tmin_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Tminf(i), i=1,Nhru)
          ELSE
            READ ( Tmin_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Tminf(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Tminf', ios, ierr)
          Basin_tmax = 0.0D0
          Basin_tmin = 0.0D0
          Basin_temp = 0.0D0
        ENDIF

        IF ( Climate_precip_flag==1 ) THEN
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Precip_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Hru_ppt(i), i=1,Nhru)
          ELSE
            READ ( Precip_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Hru_ppt(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Hru_ppt', ios, ierr)
          Basin_ppt = 0.0D0
          Basin_rain = 0.0D0
          Basin_snow = 0.0D0
          Basin_obs_ppt = 0.0D0
        ENDIF

        IF ( Climate_potet_flag==1 ) THEN
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Et_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Potet(i), i=1,Nhru)
          ELSE
            READ ( Et_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Potet(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Potet', ios, ierr)
          Basin_potet = 0.0D0
        ENDIF

        IF ( Climate_swrad_flag==1 ) THEN
          IF ( Orad_flag==0 ) THEN
            IF ( Cbh_binary_flag==0 ) THEN
              READ ( Swrad_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Swrad(i), i=1,Nhru)
            ELSE
              READ ( Swrad_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Swrad(i), i=1,Nhru)
            ENDIF
          ELSE
            IF ( Cbh_binary_flag==0 ) THEN
              READ ( Swrad_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Swrad(i), i=1,Nhru), Orad
            ELSE
              READ ( Swrad_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Swrad(i), i=1,Nhru), Orad
            ENDIF
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Swrad', ios, ierr)
          Basin_potsw = 0.0D0
        ENDIF

        IF ( Climate_transp_flag==1 ) THEN
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Transp_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Transp_on(i), i=1,Nhru)
          ELSE
            READ ( Transp_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Transp_on(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Transp_on', ios, ierr)
          Basin_transp_on = 0
        ENDIF

        IF ( Humidity_cbh_flag==1 ) THEN
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Humidity_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Humidity_hru(i), i=1,Nhru)
          ELSE
            READ ( Humidity_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Humidity_hru(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Humidity_hru', ios, ierr)
          Basin_humidity = 0.0D0
        ENDIF

        IF ( Windspeed_cbh_flag==1 ) THEN
          IF ( Cbh_binary_flag==0 ) THEN
            READ ( Windspeed_unit, *, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Windspeed_hru(i), i=1,Nhru)
          ELSE
            READ ( Windspeed_unit, IOSTAT=ios ) yr, mo, dy, hr, mn, sec, (Windspeed_hru(i), i=1,Nhru)
          ENDIF
          IF ( Cbh_check_flag==1 ) CALL read_cbh_date(yr, mo, dy, 'Windspeed_hru', ios, ierr)
          Basin_windspeed = 0.0D0
        ENDIF

        IF ( ierr/=0 ) STOP

        adjmix = Adjmix_rain(Nowmonth)
        allrain = Tmax_allrain_f(Nowmonth)
        missing = 0
        DO jj = 1, Active_hrus
          i = Hru_route_order(jj)
          harea = Hru_area(i)

          IF ( Climate_temp_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) THEN
              CALL check_cbh_value('Tmaxf', Tmaxf(i), -99.0, 150.0, missing)
              CALL check_cbh_value('Tminf', Tminf(i), -99.0, 150.0, missing)
            ENDIF
            tmax_hru = Tmaxf(i) + Tmax_cbh_adj(i)
            tmin_hru = Tminf(i) + Tmin_cbh_adj(i)
            CALL temp_set(i, tmax_hru, tmin_hru, Tmaxf(i), Tminf(i), &
     &                    Tavgf(i), Tmaxc(i), Tminc(i), Tavgc(i), harea)
          ENDIF

          IF ( Climate_potet_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) CALL check_cbh_value('Potet', Potet(i), 0.0, 50.0, missing)
            Potet(i) = Potet(i)*Potet_cbh_adj(i, Nowmonth)
            Basin_potet = Basin_potet + Potet(i)*harea
          ENDIF

          IF ( Climate_swrad_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) CALL check_cbh_value('Swrad', Swrad(i), 0.0, 1000.0, missing)
            Basin_potsw = Basin_potsw + Swrad(i)*harea
          ENDIF

          IF ( Climate_transp_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) CALL check_cbh_intvalue('Transp_on', Transp_on(i), 0, 1, missing)
            IF ( Transp_on(i)==1 ) Basin_transp_on = 1
          ENDIF

          IF ( Climate_precip_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) CALL check_cbh_value('Hru_ppt', Hru_ppt(i), 0.0, 30.0, missing)

!******Initialize HRU variables
            Pptmix(i) = 0
            Newsnow(i) = 0
            Prmx(i) = 0.0
            Hru_rain(i) = 0.0
            Hru_snow(i) = 0.0

            ! ignore very small amounts of precipitation
            IF ( Hru_ppt(i)<NEARZERO ) THEN
              Hru_ppt(i) = 0.0
            ELSE
              IF ( Precip_units==1 ) Hru_ppt(i) = Hru_ppt(i)*MM2INCH
              ppt = Hru_ppt(i)
              CALL precip_form(ppt, Hru_ppt(i), Hru_rain(i), Hru_snow(i), &
     &                         Tmaxf(i), Tminf(i), Pptmix(i), Newsnow(i), &
     &                         Prmx(i), allrain, &
     &                         Rain_cbh_adj(i,Nowmonth), Snow_cbh_adj(i,Nowmonth), &
     &                         adjmix, harea, Basin_obs_ppt, Tmax_allsnow_f)
            ENDIF
          ENDIF

          IF ( Humidity_cbh_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) CALL check_cbh_value('Humidity_hru', Humidity_hru(i), 0.0, 100.0, missing)
            IF ( missing==0 ) Basin_humidity = Basin_humidity + Humidity_hru(i)*harea
          ENDIF

          IF ( Windspeed_cbh_flag==1 ) THEN
            IF ( Cbh_check_flag==1 ) CALL check_cbh_value('Windspeed_hru', Windspeed_hru(i), 0.0, 400.0, missing)
            IF ( missing==0 ) Basin_windspeed = Basin_windspeed + Windspeed_hru(i)*harea
          ENDIF
        ENDDO

        IF ( missing==1 ) THEN
          CALL print_date(0)
          STOP
        ENDIF

        IF ( Climate_temp_flag==1 ) THEN
          Basin_tmax = Basin_tmax*Basin_area_inv
          Basin_tmin = Basin_tmin*Basin_area_inv
          Basin_temp = Basin_temp*Basin_area_inv
          Solrad_tmax = Basin_tmax
          Solrad_tmin = Basin_tmin
        ENDIF

        IF ( Climate_precip_flag==1 ) THEN
          Basin_ppt = Basin_ppt*Basin_area_inv
          Basin_obs_ppt = Basin_obs_ppt*Basin_area_inv
          Basin_rain = Basin_rain*Basin_area_inv
          Basin_snow = Basin_snow*Basin_area_inv
        ENDIF
        IF ( Climate_potet_flag==1 ) Basin_potet = Basin_potet*Basin_area_inv
        IF ( Climate_swrad_flag==1 ) THEN
          Basin_horad = Soltab_basinpotsw(Jday)
          IF ( Orad_flag==0 ) Orad = (Swrad(1)*Hru_cossl(1)*Basin_horad)/Soltab_potsw(Jday,1) ! ??bad assumption using HRU 1
          Basin_potsw = Basin_potsw*Basin_area_inv
        ENDIF
        IF ( Humidity_cbh_flag==1 ) Basin_humidity = Basin_humidity*Basin_area_inv
        IF ( Windspeed_cbh_flag==1 ) Basin_windspeed = Basin_windspeed*Basin_area_inv

      ELSEIF ( Process(:4)=='decl' ) THEN
        Version_climate_hru = '$Id: climate_hru.f90 7115 2015-01-06 00:09:15Z rsregan $'
        MODNAME = 'climate_hru'

        IF ( control_integer(Cbh_check_flag, 'cbh_check_flag')/=0 ) Cbh_check_flag = 1
        IF ( control_integer(Cbh_binary_flag, 'cbh_binary_flag')/=0 ) Cbh_binary_flag = 0

        IF ( Climate_temp_flag==1 .OR. Model==99 ) CALL print_module(Version_climate_hru, 'Temperature Distribution    ', 90)
        IF ( Climate_precip_flag==1 .OR. Model==99 ) CALL print_module(Version_climate_hru, 'Precipitation Distribution  ', 90)
        IF ( Climate_swrad_flag==1 .OR. Model==99 ) CALL print_module(Version_climate_hru, 'Solar Radiation Distribution', 90)
        IF ( Climate_potet_flag==1 .OR. Model==99 ) CALL print_module(Version_climate_hru, 'Potential Evapotranspiration', 90)
        IF ( Climate_transp_flag==1 .OR. Model==99 ) CALL print_module(Version_climate_hru, 'Transpiration Distribution  ', 90)
        IF ( Humidity_cbh_flag==1 .OR. Model==99 ) THEN
          IF ( declvar(MODNAME, 'basin_humidity', 'one', 1, 'double', &
     &         'Basin area-weighted average humidity', &
     &         'decimal fraction', Basin_humidity)/=0 ) CALL read_error(3, 'basin_humidity')
          ALLOCATE ( Humidity_hru(Nhru) )
          IF ( declvar(MODNAME, 'humidity_hru', 'nhru', Nhru, 'real', &
     &         'Relative humidity of each HRU', &
     &         'decimal fraction', Humidity_hru)/=0 ) CALL read_error(3, 'humidity_hru')
        ENDIF
        IF ( Windspeed_cbh_flag==1 .OR. Model==99 ) THEN
          IF ( declvar(MODNAME, 'basin_windspeed', 'one', 1, 'double', &
     &         'Basin area-weighted average wind speed', &
     &         'meters/second', Basin_windspeed)/=0 ) CALL read_error(3, 'basin_windspeed')
          ALLOCATE ( Windspeed_hru(Nhru) )
          IF ( declvar(MODNAME, 'windspeed_hru', 'nhru', Nhru, 'real', &
     &         'Area of HRU that is impervious', &
     &         'meters/second', Windspeed_hru)/=0 ) CALL read_error(3, 'windspeed_hru')
        ENDIF

!   Declared Parameters
        IF ( Climate_temp_flag==1 .OR. Model==99 ) THEN
          ALLOCATE ( Tmax_cbh_adj(Nhru) )
          IF ( declparam(MODNAME, 'tmax_cbh_adj', 'nhru', 'real', &
     &         '0.0', '-10.0', '10.0', &
     &         'HRU maximum temperature adjustment', &
     &         'Adjustment to maximum air temperature for each HRU, estimated on the basis of slope and aspect', &
     &         'temp_units')/=0 ) CALL read_error(1, 'tmax_cbh_adj')

          ALLOCATE ( Tmin_cbh_adj(Nhru) )
          IF ( declparam(MODNAME, 'tmin_cbh_adj', 'nhru', 'real', &
     &         '0.0', '-10.0', '10.0', &
     &         'HRU minimum temperature adjustment', &
     &         'Adjustment to minimum air temperature for each HRU, estimated on the basis of slope and aspect', &
     &         'temp_units')/=0 ) CALL read_error(1, 'tmin_cbh_adj')
        ENDIF

        IF ( Climate_precip_flag==1 .OR. Model==99 ) THEN
          IF ( declparam(MODNAME, 'adj_by_hru', 'one', 'integer', &
     &         '1', '0', '1', &
     &         'Adjust precipitation by HRU or subbasin (0=subbasin; 1=HRU)', &
     &         'Flag to indicate whether to adjust precipitation and'// &
     &         ' air temperature by HRU or subbasin (0=subbasin; 1=HRU)', &
     &         'none')/=0 ) CALL read_error(1, 'adj_by_hru')

          ALLOCATE ( Rain_cbh_adj(Nhru,12) )
          IF ( declparam(MODNAME, 'rain_cbh_adj', 'nhru,nmonths', 'real', &
     &         '1.0', '0.5', '2.0', &
     &         'Rain adjustment factor, by month for each HRU', &
     &         'Monthly (January to December) adjustment factor to'// &
     &         ' measured precipitation determined to be rain on'// &
     &         ' each HRU to account for differences in elevation, and so forth', &
     &         'decimal fraction')/=0 ) CALL read_error(1, 'rain_cbh_adj')

          ALLOCATE ( Snow_cbh_adj(Nhru,12) )
          IF ( declparam(MODNAME, 'snow_cbh_adj', 'nhru,nmonths', 'real', &
     &         '1.0', '0.5', '2.0', &
     &         'Snow adjustment factor, by month for each HRU', &
     &         'Monthly (January to December) adjustment factor to'// &
     &         ' measured precipitation determined to be snow on'// &
     &         ' each HRU to account for differences in elevation, and so forth', &
     &         'decimal fraction')/=0 ) CALL read_error(1, 'snow_cbh_adj')

          IF ( Nsub>0 ) THEN
            ALLOCATE ( Hru_subbasin(Nhru) )
            IF ( declparam(MODNAME, 'hru_subbasin', 'nhru', 'integer', &
     &           '0', 'bounded', 'nsub', &
     &           'Index of subbasin assigned to each HRU', &
     &           'Index of subbasin assigned to each HRU', &
     &           'none')/=0 ) CALL read_error(1, 'hru_subbasin')

            ALLOCATE ( Rain_sub_adj(Nsub,12) )
            IF ( declparam(MODNAME, 'rain_sub_adj', 'nsub,nmonths', 'real', &
     &           '1.0', '0.5', '2.0', &
     &           'Rain adjustment factor for each subbasin and month', &
     &           'Monthly (January to December) rain adjustment factor to'// &
     &           ' measured precipitation for each subbasin', &
     &           'decimal fraction')/=0 ) CALL read_error(1, 'rain_sub_adj')

            ALLOCATE ( Snow_sub_adj(Nsub,12) )
            IF ( declparam(MODNAME, 'snow_sub_adj', 'nsub,nmonths', &
     &           'real', '1.0', '0.5', '2.0', &
     &           'Snow adjustment factor for each subbasin and month', &
     &           'Monthly (January to December) snow adjustment factor to'// &
     &           ' measured precipitation for each subbasin', &
     &           'decimal fraction')/=0 ) CALL read_error(1, 'snow_sub_adj')
          ENDIF
        ENDIF

        IF ( Climate_potet_flag==1 .OR. Model==99 ) THEN
          ALLOCATE ( Potet_cbh_adj(Nhru,12) )
          IF ( declparam(MODNAME, 'potet_cbh_adj', 'nhru,nmonths', 'real', &
     &         '1.0', '0.5', '1.5', &
     &         'Potential ET adjustment factor, by month for each HRU', &
     &         'Monthly (January to December) adjustment factor to'// &
     &         ' potential evapotranspiration specified in CBH Files for each HRU', &
     &         'decimal fraction')/=0 ) CALL read_error(1, 'potet_cbh_adj')
        ENDIF

      ELSEIF ( Process(:4)=='init' ) THEN
        Basin_humidity = 0.0D0
        Basin_windspeed = 0.0D0
        IF ( Humidity_cbh_flag==1 ) Humidity_hru = 0.0
        IF ( Windspeed_cbh_flag==1 ) Windspeed_hru = 0.0

        istop = 0
        ierr = 0

        IF ( Climate_precip_flag==1 ) THEN
          IF ( getparam(MODNAME, 'adj_by_hru', 1, 'integer', Adj_by_hru)/=0 ) CALL read_error(2, 'adj_by_hru')
          IF ( Adj_by_hru==0 ) THEN
            IF ( Nsub==0 ) THEN
              PRINT *, 'ERROR, in climate_hru: adj_by_hru=0 and nsub=0'
              PRINT *, 'must have subbasins to adjust precipitation by subbasin'
              istop = 1
            ELSE
              IF ( Subbasin_flag==0 ) THEN
                PRINT *, 'WARNING, in climate_hru: subbasin_flag and adj_by_hru = 0'
                PRINT *, 'precipitation is adjusted using snow_sub_adj and rain_sub_adj'
                PRINT *, 'if you do not want to use subbasin adjustments set parameter adj_by_hru = 1'
              ENDIF
              IF ( getparam(MODNAME, 'hru_subbasin', Nhru, 'integer', Hru_subbasin)/=0 ) CALL read_error(2, 'hru_subbasin')
              IF ( getparam(MODNAME, 'rain_sub_adj', Nsub*12, 'real', Rain_sub_adj)/=0 ) CALL read_error(2, 'rain_sub_adj')
              IF ( getparam(MODNAME, 'snow_sub_adj', Nsub*12, 'real', Snow_sub_adj)/=0 ) CALL read_error(2, 'snow_sub_adj')
              Snow_cbh_adj = 1.0
              Rain_cbh_adj = 1.0
              DO k = 1, Active_hrus
                i = Hru_route_order(k)
                DO j = 1, 12
                  jj = Hru_subbasin(i)
                  IF ( jj==0 .OR. jj>nsub ) THEN
                    PRINT *, 'ERROR, for adj_by_hru=0 all active HRUs must be in a subbasin between 1 and', Nsub
                    PRINT *, 'For HRU:', i, ' hru_subbasin is specified as:', jj
                    istop = 1
                  ELSE
                    Snow_cbh_adj(i, j) = Snow_sub_adj(jj, j)
                    Rain_cbh_adj(i, j) = Rain_sub_adj(jj, j)
                  ENDIF
                ENDDO
              ENDDO
            ENDIF
          ELSE
            IF ( getparam(MODNAME, 'rain_cbh_adj', Nhru*12, 'real', Rain_cbh_adj)/=0 ) CALL read_error(2, 'rain_cbh_adj')
            IF ( getparam(MODNAME, 'snow_cbh_adj', Nhru*12, 'real', Snow_cbh_adj)/=0 ) CALL read_error(2, 'snow_cbh_adj')
          ENDIF

          IF ( control_string(Precip_day, 'precip_day')/=0 ) CALL read_error(5, 'precip_day')
          CALL find_header_end(Precip_unit, Precip_day, 'precip_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Precip_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Precip_day
              istop = 1
            ENDIF
          ENDIF
          !IF ( Nsub>0 ) DEALLOCATE ( Hru_subbasin, Rain_sub_adj, Snow_sub_adj )
        ENDIF

        IF ( Climate_temp_flag==1 ) THEN
          IF ( getparam(MODNAME, 'tmax_cbh_adj', Nhru, 'real', Tmax_cbh_adj)/=0 ) CALL read_error(2, 'tmax_cbh_adj')
          IF ( getparam(MODNAME, 'tmin_cbh_adj', Nhru, 'real', Tmin_cbh_adj)/=0 ) CALL read_error(2, 'tmin_cbh_adj')

          IF ( control_string(Tmax_day, 'tmax_day')/=0 ) CALL read_error(5, 'tmax_day')
          IF ( control_string(Tmin_day, 'tmin_day')/=0 ) CALL read_error(5, 'tmin_day')
          CALL find_header_end(Tmax_unit, Tmax_day, 'tmax_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Tmax_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Tmax_day
              istop = 1
            ENDIF
          ENDIF
          CALL find_header_end(Tmin_unit, Tmin_day, 'tmin_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Tmin_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Tmin_day
              istop = 1
            ENDIF
          ENDIF
        ENDIF

        IF ( Climate_potet_flag==1 ) THEN
          IF ( getparam(MODNAME, 'potet_cbh_adj', Nhru*12, 'real', Potet_cbh_adj)/=0 ) CALL read_error(2, 'potet_cbh_adj')
          IF ( control_string(Potet_day, 'potet_day')/=0 ) CALL read_error(5, 'potet_day')
          CALL find_header_end(Et_unit, Potet_day, 'potet_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Et_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Potet_day
              istop = 1
            ENDIF
          ENDIF
        ENDIF

        IF ( Climate_transp_flag==1 ) THEN
          IF ( control_string(Transp_day, 'transp_day')/=0 ) CALL read_error(5, 'transp_day')
          CALL find_header_end(Transp_unit, Transp_day, 'transp_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Transp_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Transp_day
              istop = 1
            ENDIF
          ENDIF
        ENDIF

        IF ( Climate_swrad_flag==1 ) THEN
          IF ( control_string(Swrad_day, 'swrad_day')/=0 ) CALL read_error(5, 'swrad_day')
          CALL find_header_end(Swrad_unit, Swrad_day, 'swrad_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Swrad_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Swrad_day
              istop = 1
            ENDIF
          ENDIF
        ENDIF

        IF ( Humidity_cbh_flag==1 ) THEN
          IF ( control_string(Humidity_day, 'humidity_day')/=0 ) CALL read_error(5, 'humidity_day')
          CALL find_header_end(Humidity_unit, Humidity_day, 'humidity_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Humidity_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Humidity_day
              istop = 1
            ENDIF
          ENDIF
        ENDIF

        IF ( Windspeed_cbh_flag==1 ) THEN
          IF ( control_string(Windspeed_day, 'windspeed_day')/=0 ) CALL read_error(5, 'windspeed_day')
          CALL find_header_end(Windspeed_unit, Windspeed_day, 'windspeed_day', ierr, 1, Cbh_binary_flag)
          IF ( ierr==1 ) THEN
            istop = 1
          ELSE
            CALL find_current_time(Windspeed_unit, Start_year, Start_month, Start_day, ierr, Cbh_binary_flag)
            IF ( ierr==-1 ) THEN
              PRINT *, 'for first time step, CBH File: ', Windspeed_day
              istop = 1
            ENDIF
          ENDIF
        ENDIF

        IF ( istop==1 ) STOP 'ERROR in climate_hru'

      ENDIF

      END FUNCTION climate_hru

!***********************************************************************
!     Read a day in the CBH File
!***********************************************************************
      SUBROUTINE read_cbh_date(Year, Month, Day, Var, Ios, Iret)
      USE PRMS_SET_TIME, ONLY: Nowyear, Nowmonth, Nowday
! Argument
      INTEGER, INTENT(IN) :: Year, Month, Day, Ios
      CHARACTER(LEN=*), INTENT(IN) :: Var
      INTEGER, INTENT(INOUT) :: Iret
! Functions
      EXTERNAL :: print_date
! Local Variables
      INTEGER :: right_day
!***********************************************************************
      right_day = 1
      IF ( Year/=Nowyear .OR. Month/=Nowmonth .OR. Day/=Nowday ) right_day = 0
      IF ( Ios/=0 .OR. right_day==0 ) THEN
        PRINT *, 'ERROR, reading CBH File, variable: ', Var, ' IOSTAT=', Ios 
        IF ( Ios==-1 ) THEN
          PRINT *, '       End-of-File found'
        ELSEIF ( right_day==0 ) THEN
          PRINT *, '       Wrong day found'
        ELSE
          PRINT *, '       Invalid data value found'
        ENDIF
        CALL print_date(0)
        Iret = 1
      ENDIF
      END SUBROUTINE read_cbh_date

!***********************************************************************
!     Check CBH value limits
!***********************************************************************
      SUBROUTINE check_cbh_value(Var, Var_value, Lower_val, Upper_val, Missing)
! Argument
      REAL, INTENT(IN) :: Lower_val, Upper_val
      REAL, INTENT(INOUT) :: Var_value
      CHARACTER(LEN=*), INTENT(IN) :: Var
      INTEGER, INTENT(INOUT) :: Missing
! Functions
      INTRINSIC ISNAN
      EXTERNAL :: print_date
!***********************************************************************
      IF ( ISNAN(Var_value) ) THEN
        PRINT *, 'ERROR, NaN value found for variable: ', Var
        Var_value = 0.0
        Missing = 1
        CALL print_date(0)
      ELSEIF ( Var_value<Lower_val .OR. Var_value>Upper_val ) THEN
        PRINT *, 'ERROR, bad value, variable: ', Var, ' Value:', Var_value
        PRINT *, '       lower bound:', Lower_val, ' upper bound:', Upper_val
        Missing = 1
        CALL print_date(0)
      ENDIF
      END SUBROUTINE check_cbh_value

!***********************************************************************
!     Check CBH integer value limits
!***********************************************************************
      SUBROUTINE check_cbh_intvalue(Var, Var_value, Lower_val, Upper_val, Missing)
! Argument
      INTEGER, INTENT(IN) :: Var_value, Lower_val, Upper_val
      CHARACTER(LEN=*), INTENT(IN) :: Var
      INTEGER, INTENT(INOUT) :: Missing
! Functions
      EXTERNAL :: print_date
!***********************************************************************
      IF ( Var_value<Lower_val .OR. Var_value>Upper_val ) THEN
        PRINT *, 'ERROR, bad value, variable: ', Var, ' Value:', Var_value
        PRINT *, '       lower bound:', Lower_val, ' upper bound:', Upper_val
        Missing = 1
        CALL print_date(0)
      ENDIF
      END SUBROUTINE check_cbh_intvalue