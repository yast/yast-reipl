# Makefile.am for reipl/src

yncludedir = @yncludedir@/reipl

client_DATA =			\
	reipl.ycp		\
	reipl_auto.ycp		\
	reipl_proposal.ycp	\
	inst_reipl.ycp		\
	inst_reiplauto.ycp	\
	reipl_finish.ycp	\
	reipl_bootloader_finish.ycp

ynclude_DATA =			\
	helps.ycp		\
	wizards.ycp		\
	dialogs.ycp		\
	complex.ycp

desktop_DATA =			\
	reipl.desktop

module_DATA =			\
	Reipl.ycp

# create a symlink for local build, #145327
reipl:
	ln -sf . $@
ycpchook = reipl

EXTRA_DIST = $(client_DATA) $(ynclude_DATA) $(module_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
