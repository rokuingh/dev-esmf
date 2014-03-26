#ifndef ESMCI_SparseMsg_h
#define ESMCI_SparseMsg_h

#include <Mesh/include/ESMCI_MeshTypes.h>

#include <mpi.h>

#include <vector>
#include <map>

namespace ESMCI {

// Handles mpi communication in a sparse pattern.
// Call sequence:
// --setPattern:  This uses MPI_Reduce_scatter to determine
// how many messages will be coming to the current processor.
// Make sure that the proc list does not contain duplicates!!
// ++++++++++++
// --setSizes: This may be called either once, or, if the object
// is reused for different sized messages, more than once.  If
// all messages will always be the same, call once.  If the pattern
// stays the same, but sizes differ, call each time, but save
// on establishing the pattern.
// *************
// --resetBuffers: call just before loading the beffer
// -- pack buffer
// -- if wanted, ask if filled()
// --communicate: sends send bufs and loads into receive
// -- unpack buffers
// -- if wanted, make sure empty
// go back to *** if sizes not changed, or ++++ if sizes change


class SparseMsg {
public:

  // Manages a message buffer
  class buffer {
  public:
    friend class SparseMsg;
    // Copy size bytes into destination.  Update current
    // location in buffer.
    void pop(UChar *dest, UInt size);
    // Copy size bytes into buffer.  Update current
    // location in buffer.
    void push(const UChar *src, UInt size);

    // Size of message
    UInt msg_size() { return msize;}

    bool empty() { return cur >= (beg + msize); }
  
    UInt loc() const { return cur - beg; }
    
  private:
    UChar *beg, *end;
  public:
    UChar *cur;
  private:
    int msize;  // actual message size
    UInt bsize;  // size (with rounding to word boundary)
    UInt proc;
  };

  // ** Interface **
  SparseMsg();
  ~SparseMsg();
  // Set up the pattern of messages.  Communicates to determine
  // How many receives to post.  
  // num = number of processors I will send to
  // proc = list of processor numbers.
  void setPattern(UInt num, const UInt *proc);

  // Must be called after setPattern.  Sizes both the
  // send and receive buffers.
  // First, loop the arrays and set up the send information.
  // Next, communicates (using pattern above to post IRecv's)
  // the sizes of buffers to be sent.
  // Lastly, sizes the receive buffer.
  // Num and procs must match setPattern call
  void setSizes(UInt *sizes);

  // Reset the current points on buffers.  Call before
  // Loading up data;
  void resetBuffers();

  // Get the buffer for sending to proc
  buffer *getSendBuffer(UInt proc) {
    return procToOutBuffer[proc];
  }

  // Get the buffer for unpacking from proc
  buffer *getRecvBuffer(UInt proc) {
    return procToInBuffer[proc];
  }

  UInt numRecv() { return num_incoming; }

  // Print out debug into
  void debug_print();

  // Send out the messages, copy into recv blocks.  This
  // routine does everything in one shot.
  void communicate();

  // Post ISends, IRecvs.
  void communicate_begin();

  // Wait for messages to finish
  void communicate_end();

  // Iterators to incoming processor messages.  These will be sorted
  // by processor number.
  std::vector<UInt>::iterator inProc_begin() {return inProcs.begin();}
  std::vector<UInt>::iterator inProc_end() {return inProcs.end(); }

  // send bug Filled to send?
  bool filled();

  // recvbuf all used up?
  bool empty();

  // How many procs in comm?
  UInt commSize();

  UInt commRank();

  void clear();

private:
  std::vector<buffer> outBuffers;
  std::vector<buffer> inBuffers;
  std::map<UInt, buffer*> procToOutBuffer;
  std::map<UInt, buffer*> procToInBuffer;
  std::vector<UInt> inProcs;
  UInt nsend;
  // Pointer to the block of send buffers;
  UChar *sendBuf;
  // Pointer to the block of recv buffers;
  UChar *recvBuf;
  MPI_Comm comm;
  UInt num_incoming;
  int rank, nproc;

  // If one of the send procs is self, save the send idx.  The last receive block
  //  will be set aside for receiving self.
  bool sendself;
  UInt self_idx;
  std::vector<MPI_Request> async_request;
  std::vector<MPI_Request> async_srequest;
};

  
template<class T>
class SparsePack {
public:
  explicit SparsePack(SparseMsg::buffer &buf, T t) {buf.push((UChar*)&t, sizeof(T));}
  explicit SparsePack(SparseMsg::buffer &buf, T *t,const unsigned int n) {buf.push((UChar*)&t[0], sizeof(T)*n);}
  SparsePack() {}
  static UInt size() { return sizeof(T);}
};

template<class T>
class SparseUnpack {
public:
  explicit SparseUnpack(SparseMsg::buffer &buf, T &t) {buf.pop((UChar*)&t, sizeof(T));}
  explicit SparseUnpack(SparseMsg::buffer &buf, T *t,const unsigned int n) {buf.pop((UChar*)&t[0], sizeof(T)*n);}
  SparseUnpack() {}
};

  // specialize the classes
  template<>
  class SparsePack<double> {
  public:
    explicit SparsePack(SparseMsg::buffer &buf, double t) {buf.push((UChar*)&t, sizeof(double));}
    explicit SparsePack(SparseMsg::buffer &buf, double *from,const unsigned int n) {

      double *to = reinterpret_cast<double*>(buf.cur);
      //for(UInt i=0;i<n;i++)to[i] = from[i]; // Unroll ?
      
      unsigned int nn = (n+7) / 8;
      switch(n%8)
	{
	case 0: do { *to++ = *from++;
	  case 7:    *to++ = *from++;
	  case 6:    *to++ = *from++;
	  case 5:    *to++ = *from++;
	  case 4:    *to++ = *from++;
	  case 3:    *to++ = *from++;
	  case 2:    *to++ = *from++;
	  case 1:    *to++ = *from++;
	  } while (--nn>0);
	}      
      buf.cur=buf.cur+n*sizeof(double);
    }
    SparsePack() {}
    static UInt size() { return sizeof(double);}
  };
  
  template<>
  class SparseUnpack<double> {
  public:
    explicit SparseUnpack(SparseMsg::buffer &buf, double &t) {buf.pop((UChar*)&t, sizeof(double));}
    explicit SparseUnpack(SparseMsg::buffer &buf, double *to,const unsigned int n) {

      double *from = reinterpret_cast<double*>(buf.cur);
      //for(UInt i=0;i<n;i++)to[i] = from[i]; // Unroll ?

      unsigned int nn = (n+7) / 8;
      switch(n%8)
	{
	case 0: do { *to++ = *from++;
	  case 7:    *to++ = *from++;
	  case 6:    *to++ = *from++;
	  case 5:    *to++ = *from++;
	  case 4:    *to++ = *from++;
	  case 3:    *to++ = *from++;
	  case 2:    *to++ = *from++;
	  case 1:    *to++ = *from++;
	  } while (--nn>0);
	}      
      buf.cur=buf.cur+n*sizeof(double);
    }
    SparseUnpack() {}
  };
    

} // namespace

#endif
