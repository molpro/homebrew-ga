class Ga < Formula
  homepage "http://hpc.pnl.gov/globalarrays/"
# url "https://svn.pnl.gov/svn/hpctools/branches/ga-5-4"
  url "http://hpc.pnl.gov/globalarrays/download/ga-5-4b.tgz"
  sha256 "dfdf250dc06de9aafe2edbe70c246aff92b907d8469cb1f83bd8185593e35b9a"
  version "5.4b"

  head do
    url "https://svn.pnl.gov/svn/hpctools/trunk/ga"
    version "HEAD"
  end

  depends_on "gcc"
  depends_on :fortran
  depends_on "mpich-ga"

  def install
    ENV["PATH"] = "#{HOMEBREW_PREFIX}/bin:" + ENV["PATH"]

    system "./configure",
           "CC=mpicc",
           "FC=mpif90",
           "F77=mpif77",
           "CXX=mpicxx",
           "MPICC=mpicc",
           "MPIFC=mpif90",
           "MPIF77=mpif77",
           "MPICXX=mpicxx",
           "--enable-cxx",
           "--prefix=#{prefix}"
    system "make"
    # system "make", "check", "MPIEXEC='mpiexec -np 2'"
    system "make", "install"
  end

  test do
    (testpath/"hello.c").write <<-EOS.undent
      #include <mpi.h>
      #include <stdio.h>

      int main()
      {
        int size, rank, nameLen;
        int testpattern;
        int pattern=999;
        char name[MPI_MAX_PROCESSOR_NAME];
        MPI_Init(NULL, NULL);
        GA_Initialize();
        MPI_Comm_size(MPI_COMM_WORLD, &size);
        MPI_Comm_rank(MPI_COMM_WORLD, &rank);
        MPI_Get_processor_name(name, &nameLen);
        testpattern=pattern;
        GA_Brdcst(&testpattern,sizeof(testpattern),0);
        printf("[%d/%d] Hello, world! My name is %s; broadcast error=%d.\\n", rank, size, name,testpattern-pattern);
        GA_Terminate();
        MPI_Finalize();
        return testpattern != pattern;
      }
    EOS
    ldflags = `#{bin}/ga-config --ldflags --libs`
    system("mpicc hello.c -o hello "+ldflags)
    system "./hello"
    system "mpirun", "-np", "4", "./hello"
  end
end
