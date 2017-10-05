/*
    Copyright 2017 Sergei Egorov
 
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
 
    http://www.apache.org/licenses/LICENSE-2.0
 
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#define _GNU_SOURCE
#include <pthread.h>
#include <unistd.h>
#include <sys/types.h>
#include "include/lxpthread.h"

/*
 * Sets a unique name for a thread..
 *
 * Parameters:
 * - thread: The argument specifies the thread whose name is to be changed.
 * - name:   Specifies the new name.
 *
 * Returns:
 * - 0 on success
 * - ERANGE: The length of the string specified pointed to by name exceeds the allowed limit.
 *
 */

int
linux_pthread_setname_np(pthread_t thread, const char *name)
{
    return pthread_setname_np(thread, name);
}

/*
 * Retrieve the name of the thread.
 *
 * Parameters:
 * - thread: The argument specifies the thread whose name is to be retrieved.
 * - name:   The buffer is used to return the thread name.
 * - len:    Specifies the number of bytes available in buffer.
 *
 * Returns:
 * - 0 on success
 * - ERANGE: The buffer specified by name and len is too small to hold the thread name.
 *
 */

int
linux_pthread_getname_np(pthread_t thread, char *name, size_t len)
{
    return pthread_getname_np(thread, name, len);
}
