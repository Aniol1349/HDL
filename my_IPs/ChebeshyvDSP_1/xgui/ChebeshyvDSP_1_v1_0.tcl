# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.STATE_BUFFER { PARAM_VALUE.STATE_BUFFER } {
	# Procedure called to update STATE_BUFFER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STATE_BUFFER { PARAM_VALUE.STATE_BUFFER } {
	# Procedure called to validate STATE_BUFFER
	return true
}

proc update_PARAM_VALUE.STATE_PASS_THROUGH { PARAM_VALUE.STATE_PASS_THROUGH } {
	# Procedure called to update STATE_PASS_THROUGH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.STATE_PASS_THROUGH { PARAM_VALUE.STATE_PASS_THROUGH } {
	# Procedure called to validate STATE_PASS_THROUGH
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.STATE_PASS_THROUGH { MODELPARAM_VALUE.STATE_PASS_THROUGH PARAM_VALUE.STATE_PASS_THROUGH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STATE_PASS_THROUGH}] ${MODELPARAM_VALUE.STATE_PASS_THROUGH}
}

proc update_MODELPARAM_VALUE.STATE_BUFFER { MODELPARAM_VALUE.STATE_BUFFER PARAM_VALUE.STATE_BUFFER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.STATE_BUFFER}] ${MODELPARAM_VALUE.STATE_BUFFER}
}

