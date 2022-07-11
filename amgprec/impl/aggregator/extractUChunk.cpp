#include "MatchBoxPC.h"

void extractUChunk(
    vector<MilanLongInt> &UChunkBeingProcessed,
    staticQueue &U,
    staticQueue &privateU)
{

    UChunkBeingProcessed.clear();
#pragma omp critical(U)
    {

        if (U.empty() && !privateU.empty()) // If U is empty but there are nodes in private U
            while (!privateU.empty())
                U.push_back(privateU.pop_front());

        for (int i = 0; i < UCHUNK; i++)
        { // Pop the new nodes
            if (U.empty())
                break;
            UChunkBeingProcessed.push_back(U.pop_front());
        }

    } // End of critical U
}