/*
 * Copyright 1997, Regents of the University of Minnesota
 *
 * metis.h
 *
 * This file includes all necessary header files
 *
 * Started 8/27/94
 * George
 *
 * $Id$
 */

/*
#define	DEBUG		1
#define	DMALLOC		1
*/

#include "stdheaders.h"

#ifdef DMALLOC
#include "dmalloc.h"
#endif

#define IDXTYPE_INT

/* Indexes are as long as integers for now */
#ifdef IDXTYPE_INT
typedef int idxtype;
#else
typedef short idxtype;
#endif


#include "defs.h"
#include "struct.h"
#include "macros.h"
#include "rename.h"
#include "proto.h"

