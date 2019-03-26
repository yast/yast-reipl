FROM yastdevel/ruby:sle15-sp1
COPY . /usr/src/app
# a workaround to allow package building on a non-s390 machine
RUN sed -i "/^ExclusiveArch:/d" package/*.spec
RUN git update-index --assume-unchanged package/*.spec

