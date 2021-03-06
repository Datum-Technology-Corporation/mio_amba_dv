// 
// Copyright 2021 Datum Technology Corporation
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// 
// Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
// not use this file except in compliance with the License, or, at your option,
// the Apache License version 2.0. You may obtain a copy of the License at
// 
//     https://solderpad.org/licenses/SHL-2.1/
// 
// Unless required by applicable law or agreed to in writing, any work
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// 


`ifndef __UVMA_APB_MON_SV__
`define __UVMA_APB_MON_SV__


/**
 * Component sampling transactions from a AMBA Advanced Peripheral Bus virtual interface
 * (uvma_apb_if).
 */
class uvma_apb_mon_c extends uvm_monitor;
   
   // Objects
   uvma_apb_cfg_c    cfg;
   uvma_apb_cntxt_c  cntxt;
   
   // TLM
   uvm_analysis_port#(uvma_apb_mon_trn_c)  ap;
   uvm_analysis_port#(uvma_apb_mon_trn_c)  drv_rsp_ap;
   
   
   `uvm_component_utils_begin(uvma_apb_mon_c)
      `uvm_field_object(cfg  , UVM_DEFAULT)
      `uvm_field_object(cntxt, UVM_DEFAULT)
   `uvm_component_utils_end
   
   
   /**
    * Default constructor.
    */
   extern function new(string name="uvma_apb_mon", uvm_component parent=null);
   
   /**
    * 1. Ensures cfg & cntxt handles are not null.
    * 2. Builds ap.
    */
   extern virtual function void build_phase(uvm_phase phase);
   
   /**
    * Oversees monitoring, depending on the reset state, by calling mon_<pre|in|post>_reset() tasks.
    */
   extern virtual task run_phase(uvm_phase phase);
   
   /**
    * Updates the context's reset state.
    */
   extern task observe_reset();
   
   /**
    * Called by run_phase() while agent is in pre-reset state.
    */
   extern task mon_pre_reset(uvm_phase phase);
   
   /**
    * Called by run_phase() while agent is in reset state.
    */
   extern task mon_in_reset(uvm_phase phase);
   
   /**
    * Called by run_phase() while agent is in post-reset state.
    */
   extern task mon_post_reset(uvm_phase phase);
   
   /**
    * Creates trn by sampling the interface's (cntxt.vif) signals.
    */
   extern task mon_fsm(output uvma_apb_mon_trn_c trn);
   
   /**
    * TODO Describe uvma_apb_mon_c::mon_fsm_inactive()
    */
   extern task mon_fsm_inactive();
   
   /**
    * TODO Describe uvma_apb_mon_c::mon_fsm_setup()
    */
   extern task mon_fsm_setup();
   
   /**
    * TODO Describe uvma_apb_mon_c::mon_fsm_access()
    */
   extern task mon_fsm_access(output uvma_apb_mon_trn_c trn);
   
   /**
    * TODO Describe uvma_apb_mon_c::send_drv_trn()
    */
   extern task send_drv_trn(ref uvma_apb_mon_trn_c trn);
   
   /**
    * TODO Describe uvma_apb_mon_c::process_trn()
    */
   extern function void process_trn(ref uvma_apb_mon_trn_c trn);
   
   /**
    * TODO Describe uvma_apb_mon_c::check_signals_same()
    */
   extern task check_signals_same(ref uvma_apb_mon_trn_c trn);
   
   /**
    * TODO Describe uvma_apb_mon_c::sample_trn_from_vif()
    */
   extern task sample_trn_from_vif(output uvma_apb_mon_trn_c trn);
   
endclass : uvma_apb_mon_c


function uvma_apb_mon_c::new(string name="uvma_apb_mon", uvm_component parent=null);
   
   super.new(name, parent);
   
endfunction : new


function void uvma_apb_mon_c::build_phase(uvm_phase phase);
   
   super.build_phase(phase);
   
   void'(uvm_config_db#(uvma_apb_cfg_c)::get(this, "", "cfg", cfg));
   if (!cfg) begin
      `uvm_fatal("CFG", "Configuration handle is null")
   end
   
   void'(uvm_config_db#(uvma_apb_cntxt_c)::get(this, "", "cntxt", cntxt));
   if (!cntxt) begin
      `uvm_fatal("CNTXT", "Context handle is null")
   end
   
   ap         = new("ap"        , this);
   drv_rsp_ap = new("drv_rsp_ap", this);
  
endfunction : build_phase


task uvma_apb_mon_c::run_phase(uvm_phase phase);
   
   super.run_phase(phase);
   
   fork
      observe_reset();
      
      begin
         forever begin
            wait (cfg.enabled);
            
            fork
               begin
                  case (cntxt.reset_state)
                     UVMA_APB_RESET_STATE_PRE_RESET : mon_pre_reset (phase);
                     UVMA_APB_RESET_STATE_IN_RESET  : mon_in_reset  (phase);
                     UVMA_APB_RESET_STATE_POST_RESET: mon_post_reset(phase);
                  endcase
               end
               
               begin
                  wait (!cfg.enabled);
               end
            join_any
            disable fork;
         end
      end
   join_none
   
endtask : run_phase


task uvma_apb_mon_c::observe_reset();
   
   forever begin
      wait (cfg.enabled);
      
      fork
         begin
            wait (cntxt.vif.reset_n === 0);
            cntxt.reset_state = UVMA_APB_RESET_STATE_IN_RESET;
            wait (cntxt.vif.reset_n === 1);
            cntxt.reset_state = UVMA_APB_RESET_STATE_POST_RESET;
         end
         
         begin
            wait (!cfg.enabled);
         end
      join_any
      disable fork;
   end
   
endtask : observe_reset


task uvma_apb_mon_c::mon_pre_reset(uvm_phase phase);
   
   @(cntxt.vif.mon_cb);
   
endtask : mon_pre_reset


task uvma_apb_mon_c::mon_in_reset(uvm_phase phase);
   
   @(cntxt.vif.mon_cb);
   
endtask : mon_in_reset


task uvma_apb_mon_c::mon_post_reset(uvm_phase phase);
   
   uvma_apb_mon_trn_c  trn;
   mon_fsm(trn);
   
   if (trn != null) begin
      if (cfg.enabled && cfg.is_active && (cfg.drv_mode == UVMA_APB_MODE_MSTR)) begin
         send_drv_trn(trn);
      end
      process_trn(trn);
      ap.write   (trn);
      `uvml_hrtbt()
   end
   
endtask : mon_post_reset


task uvma_apb_mon_c::mon_fsm(output uvma_apb_mon_trn_c trn);
   
   case (cntxt.mon_phase)
      UVMA_APB_PHASE_INACTIVE: mon_fsm_inactive(trn);
      UVMA_APB_PHASE_SETUP   : mon_fsm_setup   (trn);
      UVMA_APB_PHASE_ACCESS  : mon_fsm_access  (trn);
   endcase
   
endtask : mon_fsm


function void uvma_apb_mon_c::process_trn(ref uvma_apb_mon_trn_c trn);
   
   // TODO Implement uvma_apb_mon_c::process_trn()
   
endfunction : process_trn


task uvma_apb_mon_c::mon_fsm_inactive(ref uvma_apb_mon_trn_c trn);
   
   bit  is_active = 0;
   
   do begin
      @(cntxt.vif.mon_cb);
      if (cntxt.vif.mon_cb.psel[(cfg.sel_width-1):0] !== '0) begin
         foreach (cfg.mon_slv_list[ii]) begin
            if (cntxt.vif.mon_cb.psel[(cfg.sel_width-1):0] === cfg.mon_slv_list[ii]) begin
               is_active = 1;
               cntxt.mon_phase = UVMA_APB_PHASE_SETUP;
            end
         end
      end
   end while (!is_active);
   
endtask : mon_fsm_inactive


task uvma_apb_mon_c::mon_fsm_setup(ref uvma_apb_mon_trn_c trn);
   
   bit  is_enabled = 0;
   
   trn = uvma_apb_mon_trn_c::type_id::create("trn");
   sample_trn_from_vif(trn);
   
   if (cfg.enabled && cfg.is_active && (cfg.drv_mode == UVMA_APB_MODE_SLV)) begin
      send_drv_trn(trn);
   end
   
   do begin
      @(cntxt.vif.mon_cb);
      check_signals_same(trn);
      if (cntxt.vif.mon_cb.penable === 1'b1) begin
         is_enabled = 1;
         cntxt.mon_phase = UVMA_APB_PHASE_ACCESS;
      end
   end while (!is_enabled);
   
endtask : mon_fsm_setup


task uvma_apb_mon_c::mon_fsm_access(ref uvma_apb_mon_trn_c trn);
   
   bit  is_finished = 0;
   
   do begin
      if ((cntxt.vif.mon_cb.penable === 1'b1) && (cntxt.vif.mon_cb.pready === 1'b1)) begin
         is_finished = 1;
         cntxt.mon_phase = UVMA_APB_PHASE_INACTIVE;
         if (trn.access_type == UVMA_APB_ACCESS_READ) begin
            trn.data = cntxt.vif.prdata[(cfg.data_bus_width-1):0];
         end
         trn.has_error = cntxt.vif.pslverr;
      end
      else if (cntxt.vif.mon_cb.penable === 1'b0) begin
         trn.has_error = 1;
         `uvm_error("APB_MON", $sformatf("penable deasserted before pready is asserted (transfer aborted):\n%s", trn.sprint()))
         is_finished = 1;
      end
      
      @(cntxt.vif.mon_cb);
      check_signals_same(trn);
      trn.latency++;
   end while (!is_finished);
   
endtask : mon_fsm_access


task uvma_apb_mon_c::send_drv_trn(ref uvma_apb_mon_trn_c trn);
   
   drv_rsp_ap.write(trn);
   
endtask : send_drv_trn


task uvma_apb_mon_c::check_signals_same(ref uvma_apb_mon_trn_c trn);
   
   result = 1'b1;
   
   if (cntxt.vif.pwrite === 1'b1) begin
      if (trn.access_type !== UVMA_APB_ACCESS_WRITE) begin
         `uvm_error("APB_MON", $sformatf("pwrite changed before end of transfer (0->1):\n%s", trn.sprint()))
         trn.has_error = 1;
      end
      if (trn.data[(cfg.data_bus_width-1):0] !== cntxt.vif.pwdata[(cfg.data_bus_width-1):0]) begin
         `uvm_error("APB_MON", $sformatf("pwdata changed before end of transfer (%h->&h):\n%s", trn.data[(cfg.data_bus_width-1):0], cntxt.vif.pwdata[(cfg.data_bus_width-1):0], trn.sprint()))
         trn.has_error = 1;
      end
   end
   else begin
      if (trn.access_type !== UVMA_APB_ACCESS_READ) begin
         `uvm_error("APB_MON", $sformatf("pwrite changed before end of transfer (1->0):\n%s", trn.sprint()))
         trn.has_error = 1;
      end
   end
   
   if (trn.address[(cfg.addr_bus_width-1):0] !== cntxt.vif.paddr[(cfg.addr_bus_width-1):0]) begin
      `uvm_error("APB_MON", $sformatf("paddr changed before end of transfer (%h->&h):\n%s", trn.address[(cfg.addr_bus_width-1):0], cntxt.vif.pwdata[(cfg.addr_bus_width-1):0], trn.sprint()))
      trn.has_error = 1;
   end
   if (trn.slv_sel[(cfg.sel_width-1):0] !== cntxt.vif.psel[(cfg.sel_width-1):0]) begin
      `uvm_error("APB_MON", $sformatf("psel changed before end of transfer (%h->&h):\n%s", trn.slv_sel[(cfg.sel_width-1):0], cntxt.vif.psel[(cfg.sel_width-1):0], trn.sprint()))
      trn.has_error = 1;
   end
   
endtask : check_signals_same


task uvma_apb_mon_c::sample_trn_from_vif(output uvma_apb_mon_trn_c trn);
   
   trn.timestamp_start = $realtime();
   
   if (cntxt.vif.pwrite === 1'b1) begin
      trn.access_type = UVMA_APB_ACCESS_WRITE;
      trn.data[(cfg.data_bus_width-1):0] = cntxt.vif.pwdata[(cfg.data_bus_width-1):0];
   end
   else begin
      trn.access_type = UVMA_APB_ACCESS_READ;
   end
   
   trn.address[(cfg.addr_bus_width-1):0] = cntxt.vif.paddr[(cfg.addr_bus_width-1):0];
   trn.slv_sel[(cfg.sel_width     -1):0] = cntxt.vif.psel [(cfg.sel_width     -1):0];
   
endtask : sample_trn_from_vif


`endif // __UVMA_APB_MON_SV__
