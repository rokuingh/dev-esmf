#include <Mesh/include/ESMCI_SparseMsg.h>
#include <Mesh/include/ESMCI_Exception.h>
#include <Mesh/include/ESMCI_ParEnv.h>
#include <mpi.h>

#include <iostream>
#include <algorithm>

namespace ESMCI {

static UInt round_to_dword(UInt size) {
  //UInt dwsz = sizeof(void*)*4;
  UInt dwsz =128; 
  UInt rm = size % dwsz;
  return rm ? size + (dwsz - rm) : size;
}

SparseMsg::SparseMsg() :
  outBuffers(),
  inBuffers(),
  procToOutBuffer(),
  procToInBuffer(),
  inProcs(),
  nsend(0),
  sendBuf(NULL),
  recvBuf(NULL),
  comm(Par::Comm()),
  num_incoming(0),
  sendself(false),
  self_idx(0)
{
  rank = Par::Rank();
  nproc = Par::Size();
}

SparseMsg::~SparseMsg() {
  if(sendBuf != NULL){delete [] sendBuf;sendBuf=NULL;}
  if(recvBuf != NULL){delete [] recvBuf;recvBuf=NULL;}
}

void SparseMsg::setPattern(UInt num, const UInt *proc) {

  UInt csize = Par::Size();

  // Set dest proc
  nsend = num;

  std::vector<UInt> sendto(nproc, 0);
  std::vector<int> counts(nproc, 1);
  for (UInt i = 0; i < num; i++) {
    ThrowRequire(proc[i] < csize);
    sendto[proc[i]] = 1;
    if (proc[i] == (UInt) rank) {
      sendself = true;
      self_idx = i;
    }
  }

  if(sizeof(UInt)==4){
    !Par::Serial() ? MPI_Reduce_scatter(&sendto[0], &num_incoming, &*counts.begin(), MPI_UNSIGNED, MPI_SUM, comm)
      : num_incoming = sendto[0];
  }
  if(sizeof(UInt)==8){
    !Par::Serial() ? MPI_Reduce_scatter(&sendto[0], &num_incoming, &*counts.begin(), MPI_UNSIGNED_LONG, MPI_SUM, comm)
      : num_incoming = sendto[0];
  }

  // Set up send buffers (so we don't have save the proc ids
  if (nsend > 0) outBuffers.resize(nsend); else outBuffers.clear();
  for (UInt i = 0; i < nsend; i++) {
    outBuffers[i].proc = proc[i];
  }
}

void SparseMsg::setSizes(UInt *sizes) {
  // First, set up send buffers
  UInt totalsize = 0;
  // Find total buffer size; round up to word boundaries
  // for each new buffer
  for (UInt i = 0; i < nsend; i++) {
    totalsize += round_to_dword(sizes[i]);
  }

  // Allocate send buffer.  Delete in case already done
  if(sendBuf != NULL){delete [] sendBuf;sendBuf=NULL;}

  sendBuf = new UChar[totalsize+1];

  // Set up pointers into buffer
  UInt cur_loc = 0;
  for (UInt i = 0; i < nsend; i++) {
    UInt bsize = round_to_dword(sizes[i]);
    buffer &buf = outBuffers[i];
    buf.beg = outBuffers[i].cur = &sendBuf[cur_loc];
    buf.end = &sendBuf[cur_loc+bsize];
    buf.bsize = bsize;
    buf.msize = sizes[i];
    cur_loc += bsize;
    procToOutBuffer[buf.proc] = &buf;
  }
//std::cout << "last buf end:" << (int) outBuffers[nsend-1].end << ", sendbuf end:" << (int) &sendBuf[cur_loc] << std::endl;

  // Second, send sizes to receive

  // avoid allocating zero (add 1)
  std::vector<MPI_Request> request(num_incoming+1, NULL);
  std::vector<MPI_Status> status(num_incoming+1);

  // Post Recieves
  std::vector<int> inSizes(num_incoming+1);
  UInt tag0 = 0;

  UInt enD = num_incoming - (sendself ? 1 : 0);

  for (UInt i = 0; i < enD; i++) {
    MPI_Irecv(&inSizes[i], 1, MPI_INT, MPI_ANY_SOURCE, tag0, comm, &request[i]);
  }

  // Sends
  for (UInt i = 0; i < nsend; i++) {
    if (!sendself || i != self_idx) {
      buffer &buf = outBuffers[i];
      MPI_Send(&(buf.msize), 1, MPI_INT, buf.proc, tag0, comm);
    }
  }

  int ret;
  if (enD > 0) {
    ret = MPI_Waitall(enD, &request[0], &status[0]);
    if (ret != MPI_SUCCESS) 
      throw("Bad MPI_WaitAll in setSizes");
  }
  // Now set up true size
  if (sendself) inSizes[enD] = outBuffers[self_idx].msize;
 
  // Third, set up receive sizes
  if (num_incoming > 0) {
    inBuffers.resize(num_incoming);
    inProcs.resize(num_incoming);
  } else {
    // We need these to have zero sizes since users iterate through them
    inBuffers.clear();
    inProcs.clear();
  }
  
  totalsize = 0;
  for (UInt i = 0; i < enD; i++) {
    totalsize += round_to_dword(inSizes[i]);
//std::cout << "P:" << rank << ", from " << status[i].MPI_SOURCE << ", size:" << inSizes[i] << std::endl;
  }
  if(recvBuf != NULL){delete [] recvBuf;recvBuf=NULL;}

  recvBuf = new UChar[totalsize+1]; // avoid zero allocation

  
  cur_loc = 0;

  // Buffer zero is the special receive buffer from this proc.
  // Point it straight to the send buffer for this proc.  The
  // user won't even know what happened to them.
  for (UInt i = 0; i < enD; i++) {
    UInt bsize = round_to_dword(inSizes[i]);
    inBuffers[i].beg = inBuffers[i].cur = &recvBuf[cur_loc];
    inBuffers[i].end = &recvBuf[cur_loc+bsize];
    inBuffers[i].bsize = bsize;
    inBuffers[i].msize = inSizes[i];
    inBuffers[i].proc = status[i].MPI_SOURCE;
    procToInBuffer[status[i].MPI_SOURCE] = &inBuffers[i];
    inProcs[i] = status[i].MPI_SOURCE;
    cur_loc += bsize;
  }
  if (sendself) {
    UInt bsize = round_to_dword(inSizes[enD]);
    inBuffers[enD].beg = inBuffers[enD].cur = outBuffers[self_idx].beg;
    inBuffers[enD].end = outBuffers[self_idx].end;
    inBuffers[enD].bsize = bsize;
    inBuffers[enD].msize = inSizes[enD];
    inBuffers[enD].proc = rank;
    procToInBuffer[rank] = &inBuffers[enD];
    inProcs[enD] = rank;
  }

  // Sort inProcs to be conformal with CommRel
  if (num_incoming > 0) std::sort(inProcs.begin(), inProcs.end());
//std::cout << "last buf end:" << (int) inBuffers[num_incoming-1].end << ", sendbuf end:" << (int) &recvBuf[cur_loc] << std::endl;

}

void SparseMsg::communicate() {

  std::vector<MPI_Request> request(num_incoming+1, NULL);
  std::vector<MPI_Status> status(num_incoming+1);

  // Post Recieves
  UInt tag1 = 1;
  UInt enD = num_incoming - (sendself ? 1 : 0);
  for (UInt i = 0; i < enD; i++) {
    MPI_Irecv(inBuffers[i].beg, inBuffers[i].msize, MPI_BYTE, inBuffers[i].proc, tag1, comm, &request[i]);
  }

  // Sends
  for (UInt i = 0; i < nsend; i++) {
    if (!sendself || i != self_idx)
      MPI_Send(outBuffers[i].beg, outBuffers[i].msize, MPI_BYTE, outBuffers[i].proc, tag1, comm);
  }

  int ret;
  enD >0 ? ret = MPI_Waitall(enD, &request[0], &status[0]) : ret = MPI_SUCCESS;
  if (ret != MPI_SUCCESS) 
    throw("Bad MPI_WaitAll in setSizes");
  
}

void SparseMsg::communicate_begin() {

  async_request.resize(num_incoming+1, NULL);
  async_srequest.resize(nsend+1, NULL);

  // Post Recieves
  UInt tag1 = 1;
  UInt enD = num_incoming - (sendself ? 1 : 0);
  for (UInt i = 0; i < enD; i++) {
    MPI_Irecv(inBuffers[i].beg, inBuffers[i].msize, MPI_BYTE, inBuffers[i].proc, tag1, comm, &async_request[i]);
  }

  // Sends
  for (UInt i = 0; i < nsend; i++) {
    if (!sendself || i != self_idx) {
      MPI_Isend(outBuffers[i].beg, outBuffers[i].msize, MPI_BYTE, outBuffers[i].proc, tag1, comm, &async_srequest[i]);
    } else async_srequest[i] = MPI_REQUEST_NULL; 
  } 
}

void SparseMsg::communicate_end() {

  UInt enD = num_incoming - (sendself ? 1 : 0);

  {
    std::vector<MPI_Status> status(nsend+1);

    int ret;
    nsend >0 ? ret = MPI_Waitall(nsend, &async_srequest[0], &status[0]) : ret = MPI_SUCCESS;
    if (ret != MPI_SUCCESS) 
      throw("Bad MPI_WaitAll in setSizes");
  }

  {
    std::vector<MPI_Status> status(num_incoming+1);
    int ret;
    enD >0 ? ret = MPI_Waitall(enD, &async_request[0], &status[0]) : ret = MPI_SUCCESS;
    if (ret != MPI_SUCCESS) 
      throw("Bad MPI_WaitAll in setSizes");
  }

  
}

bool SparseMsg::filled() {
  for (UInt i = 0; i < nsend; i++) {
    buffer &b = outBuffers[i];
    //UInt dist = b.end - b.cur;

/*
    if (dist != 0) {
        std::cout << "buffer end-cur dist =" << dist << ", msize=" << b.msize << std::endl;
    }
*/
//std::cout << "buffer cur=" << (int) b.cur << ", end=" << (int) b.end << std::endl;
    if (b.cur > b.end) {
      //std::cout << "buffer overfilled!! cur=" << (int) b.cur << ", end=" << (int) b.end << std::endl;
      return false;
    }

    if (b.cur != &b.beg[b.msize]) {
     // std::cout << "buffer to " << b.proc << " underfilled!! cur=" << (int) b.cur << ", end=" << (int) b.end << std::endl;
      return false;
    }
  }

  return true;
}

bool SparseMsg::empty() {
  for (UInt i = 0; i < num_incoming; i++) {
    buffer &b = inBuffers[i];
//std::cout << "buffer cur=" << (int) b.cur << ", end=" << (int) b.end << std::endl;
    if (b.cur > b.end) {
      //std::cout << "buffer overpicked!! cur=" << (int) b.cur << ", end=" << (int) b.end << std::endl;
      return false;
    }

    if (b.cur != &b.beg[b.msize]) {
      //std::cout << "buffer underpicked!! cur=" << (int) b.cur << ", end=" << (int) b.end << std::endl;
      return false;
    }
  }

  return true;
}

void SparseMsg::resetBuffers() {
  for (UInt i = 0; i < nsend; i++) {
    buffer &b = outBuffers[i];
    b.cur = b.beg;
  }
  for (UInt i = 0; i < num_incoming; i++) {
    buffer &b = inBuffers[i];
    b.cur = b.beg;
  }
}

  void SparseMsg::buffer::push(const UChar * src, UInt size) {
#if 0
    for (UInt i = 0; i < size; i++) {
      *cur++ = *src++;
    }
#else
    UInt n = (size+7) / 8;
    switch(size%8)
      {
      case 0: do { *cur++ = *src++;
	case 7:      *cur++ = *src++;
	case 6:      *cur++ = *src++;
	case 5:      *cur++ = *src++;
	case 4:      *cur++ = *src++;
	case 3:      *cur++ = *src++;
	case 2:      *cur++ = *src++;
	case 1:      *cur++ = *src++;
	} while (--n>0);
      }
#endif
  }

void SparseMsg::buffer::pop(UChar *dest, UInt size) {
#if 0
  for (UInt i = 0; i < size; i++) {
    *dest++ = *cur++;
  }
#else
  UInt n = (size+7) / 8;
  switch(size%8)
    {
    case 0: do { *dest++ = *cur++;
      case 7:      *dest++ = *cur++;
      case 6:      *dest++ = *cur++;
      case 5:      *dest++ = *cur++;
      case 4:      *dest++ = *cur++;
      case 3:      *dest++ = *cur++;
      case 2:      *dest++ = *cur++;
      case 1:      *dest++ = *cur++;
      } while (--n>0);
    }
#endif
}

UInt SparseMsg::commSize() {
  return Par::Size();
}

UInt SparseMsg::commRank() {
  return Par::Rank();
}

void SparseMsg::clear() {
  if(sendBuf != NULL){delete [] sendBuf;sendBuf = NULL;}
  if(recvBuf != NULL){delete [] recvBuf;recvBuf = NULL;}

  std::vector<buffer>().swap(outBuffers);
  std::vector<buffer>().swap(inBuffers);

  std::map<UInt,buffer*>().swap(procToOutBuffer);
  std::map<UInt,buffer*>().swap(procToInBuffer);
  std::vector<UInt>().swap(inProcs); 
  nsend = 0;
  num_incoming = 0;
}

} //namespace
