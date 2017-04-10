# Sources for reipl

module_DATA = \
  modules/Reipl.rb

client_DATA = \
  clients/reipl.rb \
  clients/reipl_auto.rb \
  clients/reipl_bootloader_finish.rb \
  clients/reipl_proposal.rb \
  clients/inst_reipl.rb

yncludedir = @yncludedir@/reipl
ynclude_DATA = \
  include/reipl/wizards.rb \
  include/reipl/dialogs.rb \
  include/reipl/complex.rb \
  include/reipl/helps.rb

desktop_DATA = \
  desktop/reipl.desktop

EXTRA_DIST = $(module_DATA) $(client_DATA) $(ynclude_DATA) $(desktop_DATA)

include $(top_srcdir)/Makefile.am.common
