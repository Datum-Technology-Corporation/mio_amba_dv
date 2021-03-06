## 
## Copyright 2021 Datum Technology Corporation
## SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
## 
## Licensed under the Solderpad Hardware License v 2.1 (the "License"); you may
## not use this file except in compliance with the License, or, at your option,
## the Apache License version 2.0. You may obtain a copy of the License at
## 
##     https://solderpad.org/licenses/SHL-2.1/
## 
## Unless required by applicable law or agreed to in writing, any work
## distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
## WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
## License for the specific language governing permissions and limitations
## under the License.
## 



"""Design Verification \'Makefile\'.

Usage:
  dvm.py all  <target> [-t <test_name>] [-s <seed>]
  dvm.py cmp  <target>
  dvm.py elab <target>
  dvm.py cpel <target>
  dvm.py sim  <target> [-t <test_name>] [-s <seed>]
  dvm.py clean
  dvm.py (-h | --help)
  dvm.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.

"""



from docopt   import docopt
import os
import subprocess

dbg = True
vivado_path   = "C:/Xilinx/Vivado/2019.2/bin/"
uvm_home_path = "C:/Users/DavidOuellet-Poulin/Documents/Libraries/1800.2-2017-1.0"
uvm_dpi_so    = "uvm_dpi"
pwd           = os.getcwd()
project_dir   = pwd + "/.."
rtl_path      = project_dir + "/rtl"
rtl_libs_path = rtl_path + "/.imports"
dv_path       = project_dir + "/dv"
dv_libs_path  = project_dir + "/../mio_base_hopper/dv"



def do_dispatch(args):
    if (dbg):
        print("Call to do_dispatch()")
    do_paths()
    
    if not args['<seed>']:
        args['<seed>'] = 1
    
    if args['all']:
        args['clean'] = True
        args['cmp'  ] = True
        args['elab' ] = True
        args['sim'  ] = True
    
    if args['cpel']:
        args['clean'] = True
        args['cmp'  ] = True
        args['elab' ] = True
        args['sim'  ] = False
    
    if args['clean']:
        do_clean()
    if args['cmp']:
        do_cmp(dv_path + "/" + args['<target>'] + "/src/" + args['<target>'] + "_pkg.flist.xsim", args['<target>'])
    if args['elab']:
        do_elab(args['<target>'], args['<target>'] + "_tb")
    if args['sim']:
        do_sim(args['<target>'] + "_tb", args['<target>'] + "_" + args['<test_name>'] + "_test", args['<seed>'], [])



def do_paths():
    if (dbg):
        print("Call to do_paths()")
    
    ### RTL ###
    set_env_var("RTL_PKT_SNF_PATH", rtl_path + "/pkt_snf")
    
    ### DV ###
    # Libraries
    set_env_var("UVM_HOME"           , uvm_home_path)
    set_env_var("DV_UVM_SRC_PATH"    , uvm_home_path            + "/src")
    set_env_var("DV_UVML_HRTBT_SRC_PATH" , dv_libs_path + "/uvml_hrtbt"  + "/src")
    set_env_var("DV_UVML_TRN_SRC_PATH"   , dv_libs_path + "/uvml_trn"    + "/src")
    set_env_var("DV_UVML_LOGS_SRC_PATH"  , dv_libs_path + "/uvml_logs"   + "/src")
    set_env_var("DV_UVML_SB_SRC_PATH"    , dv_libs_path + "/uvml_sb"     + "/src")
    set_env_var("DV_UVML_RAL_SRC_PATH"   , dv_libs_path + "/uvml_ral"    + "/src")
    set_env_var("DV_UVMA_RESET_SRC_PATH" , dv_libs_path + "/uvma_reset"  + "/src")
    set_env_var("DV_UVMA_CLK_SRC_PATH"   , dv_libs_path + "/uvma_clk"    + "/src")
    set_env_var("DV_UVME_CLK_ST_SRC_PATH", dv_libs_path + "/uvme_clk_st" + "/src")
    set_env_var("DV_UVMT_CLK_ST_SRC_PATH", dv_libs_path + "/uvmt_clk_st" + "/src")
    
    # Source
    set_env_var("DV_UVMA_APB_SRC_PATH"    , dv_path + "/uvma_apb"     + "/src")
    set_env_var("DV_UVMA_AXIL_SRC_PATH"   , dv_path + "/uvma_axil"    + "/src")
    set_env_var("DV_UVMA_AXIS_SRC_PATH"   , dv_path + "/uvma_axis"    + "/src")
    set_env_var("DV_UVME_PKT_SNF_SRC_PATH", dv_path + "/uvme_pkt_snf" + "/src")
    set_env_var("DV_UVME_AXIS_ST_SRC_PATH", dv_path + "/uvme_axis_st" + "/src")
    set_env_var("DV_UVME_AXIL_ST_SRC_PATH", dv_path + "/uvme_axil_st" + "/src")
    set_env_var("DV_UVMT_PKT_SNF_SRC_PATH", dv_path + "/uvmt_pkt_snf" + "/src")
    set_env_var("DV_UVMT_AXIS_ST_SRC_PATH", dv_path + "/uvmt_axis_st" + "/src")
    set_env_var("DV_UVMT_AXIL_ST_SRC_PATH", dv_path + "/uvmt_axil_st" + "/src")



def set_env_var(name, value):
    if (dbg):
        print("Setting env var '" + name + "' to value '" + value + "'")
    os.environ[name] = value



def do_clean():
    if (dbg):
        print("Call to do_clean()")
    #os.rmdir(pwd + "/xsim.dir")



def do_cmp(filelist_path, lib_name):
    if (dbg):
        print("Call to do_cmp(filelist_path='" + filelist_path + "', lib_name='" + lib_name + "')")
    run_xsim_bin("xvlog", "-sv -f " + filelist_path + " -L uvm")



def do_elab(lib_name, design_unit):
    if (dbg):
        print("Call to do_elab(lib_name='" + lib_name + "', design_unit='" + design_unit + "')")
    run_xsim_bin("xelab", design_unit + " -relax --O0 -s " + design_unit + " -timescale 1ns/1ps")



def do_sim(snapshot, test_name, seed, args):
    args.append("SIM_DIR_RESULTS=" + pwd + "/results")
    args.append("UVM_TESTNAME=" + test_name + "_c")
    
    act_args = ""
    for arg in args:
        act_args = act_args + " -testplusarg \"" + arg + "\""
    
    os.mkdir(pwd + "/results/" + test_name + "_" + str(seed))
    
    if (dbg):
        print("Call to do_sim(snapshot='" + snapshot + "', test_name='" + test_name + "', seed='" + str(seed) + "', args='" + act_args + "')")
    
    run_xsim_bin("xsim", snapshot + " " + act_args + " -runall")



def run_xsim_bin(name, args):
    bin_path = vivado_path + name
    if (dbg):
        print("Call to run_xsim_bin(name='" + name + "', args='"  + args + "')")
        print("System call is " + bin_path + " " + args)
    subprocess.call(bin_path + " " + args, shell=True)



if __name__ == '__main__':
    args = docopt(__doc__, version='DVMake 0.1')
    if (dbg):
        print(args)
    do_dispatch(args)
