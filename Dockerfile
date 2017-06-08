FROM yastdevel/ruby:sle12-sp2
COPY . /usr/src/app

# a workaround to allow package building on a non-s390 machine
RUN sed -i "/^ExclusiveArch:/d" package/*.spec
