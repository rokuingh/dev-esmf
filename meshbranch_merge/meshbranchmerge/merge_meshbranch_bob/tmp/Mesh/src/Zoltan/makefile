# $Id$

ALL: build_here 

# Workaround an MPICH(2) issue
ESMF_CXXCOMPILECPPFLAGS += -DMPICH_IGNORE_CXX_SEEK -DZOLTAN_HG=1 -DZOLTAN_COMPRESS=1

SOURCEC	  =DD_Create.c DD_Destroy.c DD_Find.c DD_Hash2.c DD_Print.c DD_Remove.c DD_Set_Hash_Fn.c DD_Set_Neighbor_Hash_Fn1.c DD_Set_Neighbor_Hash_Fn2.c DD_Set_Neighbor_Hash_Fn3.c DD_Stats.c DD_Update.c all_allo.c assign_param_vals.c bind_param.c block.c box_assign.c build_graph.c build_machine_desc.c ch_dist_graph.c ch_init_dist.c ch_input_assign.c ch_input_geom.c ch_input_graph.c ch_input_read.c check_param.c color_test.c coloring.c comm_create.c comm_destroy.c comm_do.c comm_do_reverse.c comm_exchange_sizes.c comm_info.c comm_invert_map.c comm_invert_plan.c comm_resize.c comm_sort_ints.c costs.c create_proc_list.c cyclic.c dfs.c divide_machine.c dr_chaco_io.c dr_compress.c dr_dd.c dr_elem.c dr_elem_util.c dr_err.c dr_eval.c dr_exoII_io.c dr_gnuplot.c dr_hg_io.c dr_hg_readfile.c dr_input.c dr_loadbal.c dr_maps.c dr_migrate.c dr_mm_readfile.c dr_mmio.c dr_output.c dr_par_util.c dr_param_file.c dr_random_io.c dr_setfixed.c dr_util.c free_params.c g2l_hash.c get_processor_name.c graph.c ha_drum.c hier.c hier_free_struct.c hsfc.c hsfc_box_assign.c hsfc_hilbert.c hsfc_point_assign.c inertial1d.c inertial2d.c inertial3d.c key_params.c lb_balance.c lb_box_assign.c lb_copy.c lb_eval.c lb_free.c lb_init.c lb_invert.c lb_migrate.c lb_part2proc.c lb_point_assign.c lb_remap.c lb_set_fn.c lb_set_method.c lb_set_part_sizes.c matrix_build.c matrix_distribute.c matrix_operations.c matrix_sym.c matrix_utils.c mem.c migoct.c migreg.c migtags.c msg.c oct_plot.c oct_util.c octant.c octree.c octupdate.c order.c order_struct.c order_test.c order_tools.c output.c par_average.c par_bisect.c par_median.c par_median_randomized.c par_stats.c par_sync.c par_tflops_special.c perm.c phg.c phg_Vcycle.c phg_build.c phg_build_calls.c phg_coarse.c phg_comm.c phg_distrib.c phg_gather.c phg_hypergraph.c phg_lookup.c phg_match.c phg_order.c phg_parkway.c phg_patoh.c phg_plot.c phg_rdivide.c phg_refinement.c phg_scale.c phg_serialpartition.c phg_tree.c phg_two_ways.c phg_util.c phg_verbose.c point_assign.c postprocessing.c preprocessing.c print_params.c random.c rcb.c rcb_box.c rcb_util.c reftree_build.c reftree_coarse_path.c reftree_hash.c reftree_part.c rib.c rib_util.c rootlist.c scatter_graph.c set_param.c shared.c third_library.c timer.c timer_params.c verify_graph.c zoltan_align.c zoltan_id.c zoltan_timer.c zz_coord.c zz_gen_files.c zz_hash.c zz_heap.c zz_init.c zz_map.c zz_obj_list.c zz_rand.c zz_set_fn.c zz_sort.c zz_struct.c zz_util.c



SOURCEF	  = 

SOURCEH	  = DD.h SFC.h Zoltan_config.h all_allo_const.h ch_init_dist_const.h ch_input_const.h coloring.h coloring_const.h comm.h costs.h costs_const.h create_proc_list_const.h dfs.h dfs_const.h dr_compress_const.h dr_const.h dr_dd.h dr_elem_const.h dr_elem_util_const.h dr_err_const.h dr_eval_const.h dr_hg_readfile.h dr_input_const.h dr_loadbal_const.h dr_maps_const.h dr_mmio.h dr_output_const.h dr_par_util_const.h dr_param_file.h dr_util_const.h g2l_hash.h graph.h graph_const.h graph_util.h ha_const.h ha_drum.h hier.h hsfc.h hsfc_const.h hsfc_hilbert_const.h key_params.h lb_const.h lb_init_const.h lbi_const.h matrix.h migoct_const.h migreg.h migreg_const.h migtags_const.h msg_const.h oct_util_const.h octant_const.h octree_const.h octupdate.h octupdate_const.h order_const.h par_average_const.h par_bisect_const.h par_const.h par_median_const.h par_tflops_special_const.h params_const.h phg.h phg_comm.h phg_const.h phg_distrib.h phg_hypergraph.h phg_lookup.h phg_tree.h phg_util.h phg_verbose.h rcb.h rcb_const.h reftree.h reftree_const.h rib.h rib_const.h rootlist_const.h shared.h third_library.h third_library_const.h third_library_tools.h timer.h timer_const.h zoltan.h zoltan_align.h zoltan_comm.h zoltan_comm_cpp.h zoltan_cpp.h zoltan_dd.h zoltan_dd_cpp.h zoltan_eval.h zoltan_id.h zoltan_mem.h zoltan_timer.h zoltan_timer_cpp.h zoltan_types.h zoltan_util.h zz_const.h zz_heap.h zz_id_const.h zz_rand.h zz_sort.h zz_util_const.h




# List all .h files which should be copied to common include dir
STOREH	  = 

OBJSC     = $(addsuffix .o, $(basename $(SOURCEC)))
OBJSF     = $(addsuffix .o, $(basename $(SOURCEF)))

LIBBASE	  = libesmf
LOCDIR	  = src/Infrastructure/Mesh/src/Zoltan

CLEANDIRS   =
CLEANFILES  = 
CLOBBERDIRS =

include ${ESMF_DIR}/makefile

DIRS	  = 

# XLC++ on BGL systems has trouble with some of the Zoltan code in -O mode.
# -> this seems to be a compiler bug and we may be able to take this out once
# IBM has it fixed.
ifeq ($(ESMF_OS),Linux)
ifeq ($(ESMF_COMPILER),xlf)
ESMF_OPTLEVEL = 0
endif
endif
