# Board / Part name
PART=xc3s1200efg320-5
BOARD_NAME=nexys2


# Implementation option file
# Pick one: fast_runtime balanced high_effort overnight weekend exhaustive
IMPLEMENT=fast_runtime

# Synthesis option file
SYNTH=xst_mixed

# Working directory name
WORK=work-$(BOARD_NAME)

TOP_MODULE = la

# Source files
VHDL_SRC = BRAM8k32bit.vhd \
      clockman.vhd \
      controller.vhd \
      core.vhd \
      decoder.vhd \
      demux.vhd \
      display.vhd \
      eia232.vhd \
      filter.vhd \
      flags.vhd \
      la-$(BOARD_NAME).vhd \
      prescaler.vhd \
      receiver.vhd \
      rle_enc.vhd \
      sampler.vhd \
      sram.vhd \
      sram_bram.vhd \
      stage.vhd \
      sync.vhd \
      transmitter.vhd \
      trigger.vhd

TB_SRC = test_core_simple.vhd

.PHONY: all clean project

all: svf

xflow: project
	@rm -rf $(WORK)
	@mkdir -p $(WORK)
	@cp ucf/$(BOARD_NAME).ucf $(WORK)/$(TOP_MODULE).ucf
	@for i in $(VHDL_SRC); do ln -sf src/$$i .; done
	@for i in $(VLOG_SRC); do ln -sf src/$$i .; done
	@ln -sf la-$(BOARD_NAME).vhd la.vhd
	xflow -wd $(WORK) -rd reports -p $(PART) -synth $(SYNTH) -implement $(IMPLEMENT) -config bitgen $(TOP_MODULE) 

project:
	@rm -f $(TOP_MODULE).prj
	@echo VHDL:
	@for i in $(VHDL_SRC); do echo "    " $$i; echo vhdl work $$i >> $(TOP_MODULE).prj; done
	@echo Verilog:
	@for i in $(VLOG_SRC); do echo "    " $$i; echo verilog work $$i >> $(TOP_MODULE).prj; done

svf: xflow
	@rm -f impactrc
	@touch impactrc
	@echo "setMode -bs" >> impactrc
	@echo "setCable -port svf -file $(BOARD_NAME).svf" >> impactrc
	@echo "addDevice -p 1 -file $(XILINX)/xcf/data/xcf04s.bsd" >> impactrc
	@echo "addDevice -p 2 -file $(WORK)/$(TOP_MODULE).bit" >> impactrc
	@echo "program -p 2" >> impactrc
	@echo "closeCable" >> impactrc
	@echo "quit" >> impactrc
	@impact -batch impactrc

clean:
	rm -rf $(WORK) $(VHDL_SRC) $(VLOG_SRC) la.vhd $(TOP_MODULE).prj impactrc _impactbatch.log $(BOARD_NAME).svf
