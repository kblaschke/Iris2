#ifndef HUFFMAN_H
#define HUFFMAN_H

namespace Lugre {
	class cFIFO;
};

using namespace Lugre;

void	HuffmanCompress			(cFIFO *pInFifo, cFIFO *pOutFifo);
void	HuffmanDecompress		(cFIFO *pInFifo, cFIFO *pOutFifo);
bool	HuffmanDecompressOne	(cFIFO *pInFifo, cFIFO *pOutFifo);

#endif
