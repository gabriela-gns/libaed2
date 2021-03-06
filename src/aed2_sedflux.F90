!###############################################################################
!                                                                              !
!         .----------------.  .----------------.  .----------------.           !
!         | .--------------. || .--------------. || .--------------. |         !
!         | |    _______   | || |  ________    | || |  _________   | |         !
!         | |   /  ___  |  | || | |_   ___ `.  | || | |_   ___  |  | |         !
!         | |  |  (__ \_|  | || |   | |   `. \ | || |   | |_  \_|  | |         !
!         | |   '.___`-.   | || |   | |    | | | || |   |  _|      | |         !
!         | |  |`\____) |  | || |  _| |___.' / | || |  _| |_       | |         !
!         | |  |_______.'  | || | |________.'  | || | |_____|      | |         !
!         | |              | || |              | || |              | |         !
!         | '--------------' || '--------------' || '--------------' |         !
!         '----------------'  '----------------'  '----------------'           !
!                                                                              !
!###############################################################################
!#                                                                             #
!# aed2_sedflux.F90                                                            #
!#                                                                             #
!#  Developed by :                                                             #
!#      AquaticEcoDynamics (AED) Group                                         #
!#      School of Agriculture and Environment                                  #
!#      The University of Western Australia                                    #
!#                                                                             #
!#      http://aquatic.science.uwa.edu.au/                                     #
!#                                                                             #
!#  Copyright 2013 - 2018 -  The University of Western Australia               #
!#                                                                             #
!#   GLM is free software: you can redistribute it and/or modify               #
!#   it under the terms of the GNU General Public License as published by      #
!#   the Free Software Foundation, either version 3 of the License, or         #
!#   (at your option) any later version.                                       #
!#                                                                             #
!#   GLM is distributed in the hope that it will be useful,                    #
!#   but WITHOUT ANY WARRANTY; without even the implied warranty of            #
!#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             #
!#   GNU General Public License for more details.                              #
!#                                                                             #
!#   You should have received a copy of the GNU General Public License         #
!#   along with this program.  If not, see <http://www.gnu.org/licenses/>.     #
!#                                                                             #
!#   -----------------------------------------------------------------------   #
!#                                                                             #
!# Created May 2012                                                            #
!#                                                                             #
!###############################################################################

#include "aed2.h"

#define _MAX_ZONES_ 100
!
#define SED_CONSTANT     1
#define SED_CONSTANT_2D  2
#define SED_DYNAMIC      3
#define SED_DYNAMIC_2D   4
!
MODULE aed2_sedflux
!------------------------------------------------------------------------------+
! The AED module sediment is not truely a model in itself, rather it provides  |
! sediment flux values in a unified way to simply the interface to other models|
!------------------------------------------------------------------------------+
   USE aed2_core

   IMPLICIT NONE

   PRIVATE
!
   PUBLIC aed2_sedflux_data_t
!
   TYPE,extends(aed2_model_data_t) :: aed2_sedflux_data_t
      !# Variable identifiers
      INTEGER  :: id_Fsed_oxy, id_Fsed_rsi, id_Fsed_amm, id_Fsed_nit
      INTEGER  :: id_Fsed_frp, id_Fsed_pon, id_Fsed_don
      INTEGER  :: id_Fsed_pop, id_Fsed_dop, id_Fsed_poc, id_Fsed_doc
      INTEGER  :: id_Fsed_dic, id_Fsed_ch4, id_Fsed_feii
      INTEGER  :: id_Fsed_n2o
      INTEGER  :: id_zones

      !# Model parameters
      INTEGER  :: sed_modl, n_zones
      AED_REAL :: Fsed_oxy, Fsed_rsi, Fsed_amm, Fsed_nit, Fsed_frp, &
                  Fsed_pon, Fsed_don, Fsed_pop, Fsed_dop, &
                  Fsed_poc, Fsed_doc, Fsed_dic, Fsed_ch4, Fsed_feii, Fsed_n2o
      AED_REAL,DIMENSION(:),ALLOCATABLE :: &
                  Fsed_oxy_P, Fsed_rsi_P, Fsed_amm_P, Fsed_nit_P, Fsed_frp_P, &
                  Fsed_pon_P, Fsed_don_P, Fsed_pop_P, Fsed_dop_P, Fsed_n2o_P, &
                  Fsed_poc_P, Fsed_doc_P, Fsed_dic_P, Fsed_ch4_P, Fsed_feii_P

     CONTAINS
         PROCEDURE :: define            => aed2_define_sedflux
         PROCEDURE :: initialize        => aed2_initialize_sedflux
         PROCEDURE :: calculate_benthic => aed2_calculate_benthic_sedflux
!        PROCEDURE :: mobility          => aed2_mobility_sedflux
!        PROCEDURE :: light_extinction  => aed2_light_extinction_sedflux
!        PROCEDURE :: delete            => aed2_delete_sedflux
   END TYPE
!===============================================================================

CONTAINS


!###############################################################################
SUBROUTINE load_sed_zone_data(data,namlst)
!-------------------------------------------------------------------------------
!ARGUMENTS
   CLASS (aed2_sedflux_data_t),INTENT(inout) :: data
   INTEGER,INTENT(in)                        :: namlst
!
!LOCALS
   INTEGER  :: status

!  AED_REAL :: FsedA_initial=0.01
!  AED_REAL :: FsedN_initial=0.01

   INTEGER  :: n_zones=0
   AED_REAL :: Fsed_oxy(_MAX_ZONES_) = MISVAL, Fsed_rsi(_MAX_ZONES_) = MISVAL, &
               Fsed_amm(_MAX_ZONES_) = MISVAL, Fsed_nit(_MAX_ZONES_) = MISVAL, &
               Fsed_frp(_MAX_ZONES_) = MISVAL, Fsed_pon(_MAX_ZONES_) = MISVAL, &
               Fsed_don(_MAX_ZONES_) = MISVAL, Fsed_pop(_MAX_ZONES_) = MISVAL, &
               Fsed_dop(_MAX_ZONES_) = MISVAL, Fsed_poc(_MAX_ZONES_) = MISVAL, &
               Fsed_doc(_MAX_ZONES_) = MISVAL, Fsed_dic(_MAX_ZONES_) = MISVAL, &
               Fsed_ch4(_MAX_ZONES_) = MISVAL, Fsed_feii(_MAX_ZONES_) = MISVAL,&
               Fsed_n2o(_MAX_ZONES_) = MISVAL

   NAMELIST /aed2_sed_const2d/ n_zones, &
                              Fsed_oxy, Fsed_rsi, Fsed_amm, Fsed_nit, Fsed_frp,&
                              Fsed_pon, Fsed_don, Fsed_pop, Fsed_dop, Fsed_n2o,&
                              Fsed_poc, Fsed_doc, Fsed_dic, Fsed_ch4, Fsed_feii
!
!-------------------------------------------------------------------------------
!BEGIN
   ! Read the namelist
   read(namlst,nml=aed2_sed_const2d,iostat=status)
   IF (status /= 0) STOP 'ERROR reading namelist aed2_sed_const2d'

   data%n_zones = n_zones
   IF (Fsed_oxy(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_oxy_P(n_zones)) ; data%Fsed_oxy_P(1:n_zones) = Fsed_oxy(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_rsi(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_rsi_P(n_zones)) ; data%Fsed_rsi_P(1:n_zones) = Fsed_rsi(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_amm(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_amm_P(n_zones)) ; data%Fsed_amm_P(1:n_zones) = Fsed_amm(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_nit(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_nit_P(n_zones)) ; data%Fsed_nit_P(1:n_zones) = Fsed_nit(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_frp(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_frp_P(n_zones)) ; data%Fsed_frp_P(1:n_zones) = Fsed_frp(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_pon(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_pon_P(n_zones)) ; data%Fsed_pon_P(1:n_zones) = Fsed_pon(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_don(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_don_P(n_zones)) ; data%Fsed_don_P(1:n_zones) = Fsed_don(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_pop(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_pop_P(n_zones)) ; data%Fsed_pop_P(1:n_zones) = Fsed_pop(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_dop(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_dop_P(n_zones)) ; data%Fsed_dop_P(1:n_zones) = Fsed_dop(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_poc(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_poc_P(n_zones)) ; data%Fsed_poc_P(1:n_zones) = Fsed_poc(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_doc(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_doc_P(n_zones)) ; data%Fsed_doc_P(1:n_zones) = Fsed_doc(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_dic(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_dic_P(n_zones)) ; data%Fsed_dic_P(1:n_zones) = Fsed_dic(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_ch4(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_ch4_P(n_zones)) ; data%Fsed_ch4_P(1:n_zones) = Fsed_ch4(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_feii(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_feii_P(n_zones)) ; data%Fsed_feii_P(1:n_zones) = Fsed_feii(1:n_zones)/secs_per_day
   ENDIF
   IF (Fsed_n2o(1) .NE. MISVAL ) THEN
      ALLOCATE(data%Fsed_n2o_P(n_zones)) ; data%Fsed_n2o_P(1:n_zones) = Fsed_n2o(1:n_zones)/secs_per_day
   ENDIF
END SUBROUTINE load_sed_zone_data
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


!###############################################################################
SUBROUTINE str_tolower(s)
!-------------------------------------------------------------------------------
!ARGUMENTS
   CHARACTER(len=*), INTENT(inout) :: s
!LOCALS
   INTEGER :: len, i, ic
!
!BEGIN
!-------------------------------------------------------------------------------
   len = LEN_TRIM(s)
   DO i=1, len
      ic = ichar(s(i:i))
      IF (ic >= 65 .AND. ic < 90) s(i:i) = char(ic+32)
   ENDDO
END SUBROUTINE str_tolower
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


!###############################################################################
SUBROUTINE aed2_define_sedflux(data, namlst)
!-------------------------------------------------------------------------------
! Initialise the AED2 model
!
!  Here, the aed namelist is read and the variables exported
!  by the model are registered with AED2.
!-------------------------------------------------------------------------------
!ARGUMENTS
   CLASS (aed2_sedflux_data_t),INTENT(inout) :: data
   INTEGER,INTENT(in) :: namlst

!
!LOCALS
   INTEGER  :: status
   CHARACTER(len=64) :: sedflux_model=''
   INTEGER  :: nzones = 1
   AED_REAL :: Fsed_oxy = MISVAL, Fsed_rsi = MISVAL, Fsed_amm = MISVAL, Fsed_nit = MISVAL, &
               Fsed_pon = MISVAL, Fsed_don = MISVAL, Fsed_pop = MISVAL, Fsed_dop = MISVAL, &
               Fsed_poc = MISVAL, Fsed_doc = MISVAL, Fsed_dic = MISVAL, Fsed_frp = MISVAL, &
               Fsed_ch4 = MISVAL, Fsed_feii = MISVAL, Fsed_n2o = MISVAL

   NAMELIST /aed2_sedflux/ sedflux_model
   NAMELIST /aed2_sed_constant/ nzones,                                           &
                                Fsed_oxy, Fsed_rsi, Fsed_amm, Fsed_nit, Fsed_frp, &
                                Fsed_pon, Fsed_don, Fsed_pop, Fsed_dop, Fsed_n2o, &
                                Fsed_poc, Fsed_doc, Fsed_dic, Fsed_ch4, Fsed_feii

!
!-------------------------------------------------------------------------------
!BEGIN
   print *,"        aed2_sedflux initialization"

   ! Read the namelist
   read(namlst,nml=aed2_sedflux,iostat=status)
   IF (status /= 0) STOP 'ERROR reading namelist aed2_sedflux'

   CALL str_tolower(sedflux_model)

   data%sed_modl = -1
   IF ( sedflux_model .EQ. "constant" ) THEN
      data%sed_modl = SED_CONSTANT

      read(namlst,nml=aed2_sed_constant,iostat=status)
      IF (status /= 0) STOP 'ERROR reading namelist aed2_sed_constant'

      ! Store parameter values in our own derived type
      ! NB: all rates must be provided in values per day,
      ! and are converted here to values per second.
      data%Fsed_oxy  = Fsed_oxy / secs_per_day
      data%Fsed_rsi  = Fsed_rsi / secs_per_day
      data%Fsed_amm  = Fsed_amm / secs_per_day
      data%Fsed_nit  = Fsed_nit / secs_per_day
      data%Fsed_n2o  = Fsed_n2o / secs_per_day
      data%Fsed_frp  = Fsed_frp / secs_per_day
      data%Fsed_pon  = Fsed_pon / secs_per_day
      data%Fsed_don  = Fsed_don / secs_per_day
      data%Fsed_pop  = Fsed_pop / secs_per_day
      data%Fsed_dop  = Fsed_dop / secs_per_day
      data%Fsed_poc  = Fsed_poc / secs_per_day
      data%Fsed_doc  = Fsed_doc / secs_per_day
      data%Fsed_dic  = Fsed_dic / secs_per_day
      data%Fsed_ch4  = Fsed_ch4 / secs_per_day
      data%Fsed_feii = Fsed_feii/ secs_per_day
   ELSEIF ( sedflux_model .EQ. "dynamic" ) THEN
      data%sed_modl = SED_DYNAMIC

!     data%id_zones = aed2_locate_global_sheet('sed_zone')
      data%Fsed_oxy = 10. / secs_per_day
   ELSEIF ( sedflux_model .EQ. "constant2d" .OR. sedflux_model .EQ. "dynamic2d" ) THEN
      IF ( sedflux_model .EQ. "constant2d" ) THEN
         data%sed_modl = SED_CONSTANT_2D
      ELSE
         data%sed_modl = SED_DYNAMIC_2D
      ENDIF

      data%id_zones = aed2_locate_global_sheet('sed_zone')

      CALL load_sed_zone_data(data,namlst)
      IF (ALLOCATED(data%Fsed_oxy_P))  Fsed_oxy  = data%Fsed_oxy_P(1)
      IF (ALLOCATED(data%Fsed_rsi_P))  Fsed_rsi  = data%Fsed_rsi_P(1)
      IF (ALLOCATED(data%Fsed_amm_P))  Fsed_amm  = data%Fsed_amm_P(1)
      IF (ALLOCATED(data%Fsed_nit_P))  Fsed_nit  = data%Fsed_nit_P(1)
      IF (ALLOCATED(data%Fsed_n2o_P))  Fsed_n2o  = data%Fsed_n2o_P(1)
      IF (ALLOCATED(data%Fsed_frp_P))  Fsed_frp  = data%Fsed_frp_P(1)
      IF (ALLOCATED(data%Fsed_pon_P))  Fsed_pon  = data%Fsed_pon_P(1)
      IF (ALLOCATED(data%Fsed_don_P))  Fsed_don  = data%Fsed_don_P(1)
      IF (ALLOCATED(data%Fsed_pop_P))  Fsed_pop  = data%Fsed_pop_P(1)
      IF (ALLOCATED(data%Fsed_dop_P))  Fsed_dop  = data%Fsed_dop_P(1)
      IF (ALLOCATED(data%Fsed_poc_P))  Fsed_poc  = data%Fsed_poc_P(1)
      IF (ALLOCATED(data%Fsed_doc_P))  Fsed_doc  = data%Fsed_doc_P(1)
      IF (ALLOCATED(data%Fsed_dic_P))  Fsed_dic  = data%Fsed_dic_P(1)
      IF (ALLOCATED(data%Fsed_ch4_P))  Fsed_ch4  = data%Fsed_ch4_P(1)
      IF (ALLOCATED(data%Fsed_feii_P)) Fsed_feii = data%Fsed_feii_P(1)
   ELSE
      PRINT*,"**ERROR : Unknown sedflux model type :", TRIM(sedflux_model)
   ENDIF

   ! Register state variables
   ! NOTE the "_sheet_"  which specifies the variable is benthic.
   IF ( data%Fsed_oxy .GT. MISVAL ) &
      data%id_Fsed_oxy = aed2_define_sheet_diag_variable('Fsed_oxy','mmol/m**2',   &
                                          'sedimentation rate of oxygen')
   IF ( Fsed_rsi .GT. MISVAL ) &
      data%id_Fsed_rsi = aed2_define_sheet_diag_variable('Fsed_rsi','mmol/m**2',   &
                                          'sedimentation rate of silica')
   IF ( Fsed_amm .GT. MISVAL ) &
      data%id_Fsed_amm = aed2_define_sheet_diag_variable('Fsed_amm','mmol/m**2',   &
                                          'sedimentation rate of ammonia')
   IF ( Fsed_nit .GT. MISVAL ) &
      data%id_Fsed_nit = aed2_define_sheet_diag_variable('Fsed_nit','mmol/m**2',   &
                                          'sedimentation rate of nitrate')
   IF ( Fsed_n2o .GT. MISVAL ) &
      data%id_Fsed_n2o = aed2_define_sheet_diag_variable('Fsed_n2o','mmol/m**2',   &
                                          'sedimentation rate of n2o')
   IF ( Fsed_frp .GT. MISVAL ) &
      data%id_Fsed_frp = aed2_define_sheet_diag_variable('Fsed_frp','mmol/m**2',   &
                                          'sedimentation rate of phosphorus')
   IF ( Fsed_pon .GT. MISVAL ) &
      data%id_Fsed_pon = aed2_define_sheet_diag_variable('Fsed_pon','mmol/m**2',   &
                                          'sedimentation rate of pon')
   IF ( Fsed_don .GT. MISVAL ) &
      data%id_Fsed_don = aed2_define_sheet_diag_variable('Fsed_don','mmol/m**2',   &
                                          'sedimentation rate of don')
   IF ( Fsed_pop .GT. MISVAL ) &
      data%id_Fsed_pop = aed2_define_sheet_diag_variable('Fsed_pop','mmol/m**2',   &
                                          'sedimentation rate of pop')
   IF ( Fsed_dop .GT. MISVAL ) &
      data%id_Fsed_dop = aed2_define_sheet_diag_variable('Fsed_dop','mmol/m**2',   &
                                          'sedimentation rate of dop')
   IF ( Fsed_poc .GT. MISVAL ) &
      data%id_Fsed_poc = aed2_define_sheet_diag_variable('Fsed_poc','mmol/m**2',   &
                                          'sedimentation rate of poc')
   IF ( Fsed_doc .GT. MISVAL ) &
      data%id_Fsed_doc = aed2_define_sheet_diag_variable('Fsed_doc','mmol/m**2',   &
                                          'sedimentation rate of doc')
   IF ( Fsed_dic .GT. MISVAL ) &
      data%id_Fsed_dic = aed2_define_sheet_diag_variable('Fsed_dic','mmol/m**2',   &
                                          'sedimentation rate of carbon')
   IF ( Fsed_ch4 .GT. MISVAL ) &
      data%id_Fsed_ch4 = aed2_define_sheet_diag_variable('Fsed_ch4','mmol/m**2',   &
                                          'sedimentation rate of ch4')
   IF ( Fsed_feii .GT. MISVAL ) &
      data%id_Fsed_feii = aed2_define_sheet_diag_variable('Fsed_feii','mmol/m**2', &
                                          'sedimentation rate of iron')

END SUBROUTINE aed2_define_sedflux
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++



!###############################################################################
SUBROUTINE aed2_initialize_sedflux(data, column, layer_idx)
!-------------------------------------------------------------------------------
! Routine to set initial state of SEDFLUX variables                            !
!-------------------------------------------------------------------------------
!ARGUMENTS
   CLASS (aed2_sedflux_data_t),INTENT(in) :: data
   TYPE (aed2_column_t),INTENT(inout) :: column(:)
   INTEGER,INTENT(in) :: layer_idx
!
!LOCALS
   AED_REAL :: Rzone
   INTEGER  :: zone
   ! Temporary variables
   AED_REAL :: Fsed_oxy = 0., Fsed_rsi = 0.
   AED_REAL :: Fsed_amm = 0., Fsed_nit = 0.
   AED_REAL :: Fsed_pon = 0., Fsed_don = 0.
   AED_REAL :: Fsed_pop = 0., Fsed_dop = 0.
   AED_REAL :: Fsed_poc = 0., Fsed_doc = 0.
   AED_REAL :: Fsed_dic = 0., Fsed_frp = 0.
   AED_REAL :: Fsed_ch4 = 0., Fsed_feii = 0.
   AED_REAL :: Fsed_n2o = 0.
!
!-------------------------------------------------------------------------------
!BEGIN
   IF ( data%sed_modl .LE. 0 ) RETURN

   !# Do this here because for the constant model these values never change.
   IF ( data%sed_modl .EQ. SED_CONSTANT .OR. data%sed_modl .EQ. SED_DYNAMIC ) THEN
       Fsed_oxy  = data%Fsed_oxy
       Fsed_rsi  = data%Fsed_rsi
       Fsed_amm  = data%Fsed_amm
       Fsed_nit  = data%Fsed_nit
       Fsed_n2o  = data%Fsed_n2o
       Fsed_frp  = data%Fsed_frp
       Fsed_pon  = data%Fsed_pon
       Fsed_don  = data%Fsed_don
       Fsed_pop  = data%Fsed_pop
       Fsed_dop  = data%Fsed_dop
       Fsed_poc  = data%Fsed_poc
       Fsed_doc  = data%Fsed_doc
       Fsed_dic  = data%Fsed_dic
       Fsed_ch4  = data%Fsed_ch4
       Fsed_feii = data%Fsed_feii
   ELSEIF ( data%sed_modl .EQ. SED_CONSTANT_2D .OR. data%sed_modl .EQ. SED_DYNAMIC_2D ) THEN
       !# Do the 2D variants - zone variant
       !# Get the zone array dependency
       !# select the material zone for this cell
       !# set sediment values accordingly
       !# This sets the value to the values in &aed2_sed_const2d
       Rzone = _STATE_VAR_S_(data%id_zones)
       zone = INT(Rzone)

       IF ( zone .LE. 0 .OR. zone .GT. data%n_zones ) zone = 1

       IF ( data%id_Fsed_oxy  > 0 ) Fsed_oxy  = data%Fsed_oxy_P(zone)
       IF ( data%id_Fsed_rsi  > 0 ) Fsed_rsi  = data%Fsed_rsi_P(zone)
       IF ( data%id_Fsed_amm  > 0 ) Fsed_amm  = data%Fsed_amm_P(zone)
       IF ( data%id_Fsed_nit  > 0 ) Fsed_nit  = data%Fsed_nit_P(zone)
       IF ( data%id_Fsed_n2o  > 0 ) Fsed_n2o  = data%Fsed_n2o_P(zone)
       IF ( data%id_Fsed_frp  > 0 ) Fsed_frp  = data%Fsed_frp_P(zone)
       IF ( data%id_Fsed_pon  > 0 ) Fsed_pon  = data%Fsed_pon_P(zone)
       IF ( data%id_Fsed_don  > 0 ) Fsed_don  = data%Fsed_don_P(zone)
       IF ( data%id_Fsed_pop  > 0 ) Fsed_pop  = data%Fsed_pop_P(zone)
       IF ( data%id_Fsed_dop  > 0 ) Fsed_dop  = data%Fsed_dop_P(zone)
       IF ( data%id_Fsed_poc  > 0 ) Fsed_poc  = data%Fsed_poc_P(zone)
       IF ( data%id_Fsed_doc  > 0 ) Fsed_doc  = data%Fsed_doc_P(zone)
       IF ( data%id_Fsed_dic  > 0 ) Fsed_dic  = data%Fsed_dic_P(zone)
       IF ( data%id_Fsed_ch4  > 0 ) Fsed_ch4  = data%Fsed_ch4_P(zone)
       IF ( data%id_Fsed_feii > 0 ) Fsed_feii = data%Fsed_feii_P(zone)
   ENDIF

   !# Also store sediment flux as diagnostic variable
   IF ( data%id_Fsed_oxy  > 0 ) _DIAG_VAR_S_(data%id_Fsed_oxy)  = Fsed_oxy
   IF ( data%id_Fsed_rsi  > 0 ) _DIAG_VAR_S_(data%id_Fsed_rsi)  = Fsed_rsi
   IF ( data%id_Fsed_amm  > 0 ) _DIAG_VAR_S_(data%id_Fsed_amm)  = Fsed_amm
   IF ( data%id_Fsed_nit  > 0 ) _DIAG_VAR_S_(data%id_Fsed_nit)  = Fsed_nit
   IF ( data%id_Fsed_n2o  > 0 ) _DIAG_VAR_S_(data%id_Fsed_n2o)  = Fsed_n2o
   IF ( data%id_Fsed_frp  > 0 ) _DIAG_VAR_S_(data%id_Fsed_frp)  = Fsed_frp
   IF ( data%id_Fsed_pon  > 0 ) _DIAG_VAR_S_(data%id_Fsed_pon)  = Fsed_pon
   IF ( data%id_Fsed_don  > 0 ) _DIAG_VAR_S_(data%id_Fsed_don)  = Fsed_don
   IF ( data%id_Fsed_pop  > 0 ) _DIAG_VAR_S_(data%id_Fsed_pop)  = Fsed_pop
   IF ( data%id_Fsed_dop  > 0 ) _DIAG_VAR_S_(data%id_Fsed_dop)  = Fsed_dop
   IF ( data%id_Fsed_poc  > 0 ) _DIAG_VAR_S_(data%id_Fsed_poc)  = Fsed_poc
   IF ( data%id_Fsed_doc  > 0 ) _DIAG_VAR_S_(data%id_Fsed_doc)  = Fsed_doc
   IF ( data%id_Fsed_dic  > 0 ) _DIAG_VAR_S_(data%id_Fsed_dic)  = Fsed_dic
   IF ( data%id_Fsed_ch4  > 0 ) _DIAG_VAR_S_(data%id_Fsed_ch4)  = Fsed_ch4
   IF ( data%id_Fsed_feii > 0 ) _DIAG_VAR_S_(data%id_Fsed_feii) = Fsed_feii
END SUBROUTINE aed2_initialize_sedflux
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


!###############################################################################
SUBROUTINE aed2_calculate_benthic_sedflux(data,column,layer_idx)
!-------------------------------------------------------------------------------
! Calculate pelagic bottom fluxes and benthic sink and source terms of AED sedflux
! Everything in units per surface area (not volume!) per time.
!-------------------------------------------------------------------------------
!ARGUMENTS
   CLASS (aed2_sedflux_data_t),INTENT(in) :: data
   TYPE (aed2_column_t),INTENT(inout) :: column(:)
   INTEGER,INTENT(in) :: layer_idx
!
!-------------------------------------------------------------------------------
!
   IF ( data%sed_modl .EQ. SED_CONSTANT .OR. data%sed_modl .EQ. SED_CONSTANT_2D ) &
      CALL aed2_initialize_sedflux(data, column, layer_idx)
END SUBROUTINE aed2_calculate_benthic_sedflux
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


END MODULE aed2_sedflux
