class MpichGa < Formula
  homepage "http://www.mpich.org/"
  url "http://www.mpich.org/static/downloads/3.2/mpich-3.2.tar.gz"
  mirror "https://fossies.org/linux/misc/mpich-3.2.tar.gz"
  sha256 "0778679a6b693d7b7caff37ff9d2856dc2bfc51318bf8373859bfa74253da3dc"
  revision 1

  head do
    url "git://git.mpich.org/mpich.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool"  => :build
  end

  devel do
    url "http://www.mpich.org/static/downloads/3.2a2/mpich-3.2a2.tar.gz"
    sha1 "2bea3f7cb3d69d2ea372e48f376187e91b929bb6"
  end

  deprecated_option "disable-fortran" => "without-fortran"

  depends_on :fortran => :recommended

  fails_with :clang

  conflicts_with "open-mpi", :because => "both install mpi__ compiler wrappers"
  conflicts_with "mpich2", :because => "both install mpi__ compiler wrappers"

  def install
    if build.head?
      # ensure that the consistent set of autotools built by homebrew is used to
      # build MPICH, otherwise very bizarre build errors can occur
      ENV["MPICH_AUTOTOOLS_DIR"] = HOMEBREW_PREFIX + "bin"
      system "./autogen.sh"
    end

    args = [
      "--disable-dependency-tracking",
      "--disable-silent-rules",
      "--prefix=#{prefix}",
      "--mandir=#{man}",
    ]

    args << "--disable-fortran" if build.without? "fortran"

    system "./configure", *args
    system "make"
    system "make", "testing"
    system "make", "install"
  end

  test do
    (testpath/"hello.c").write <<-EOS.undent
      #include <mpi.h>
      #include <stdio.h>

      int main()
      {
        int size, rank, nameLen;
        char name[MPI_MAX_PROCESSOR_NAME];
        MPI_Init(NULL, NULL);
        MPI_Comm_size(MPI_COMM_WORLD, &size);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
        MPI_Get_processor_name(name, &nameLen);
        printf("[%d/%d] Hello, world! My name is %s.\\n", rank, size, name);
        MPI_Finalize();
        return 0;
      }
    EOS
    system "#{bin}/mpicc", "hello.c", "-o", "hello"
    system "./hello"
    system "#{bin}/mpirun", "-np", "4", "./hello"
  end
end
