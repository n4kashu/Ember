#Number libs.
import ../../lib/BN
import ../../lib/Base

#Time lib.
import ../../lib/Time

#Merkle, Block, and Difficulty libs.
import Merkle
import Block as BlockFile
import Difficulty as DifficultyFile

#Blockchain object.
type Blockchain* = ref object of RootObj
    #Blockchain height. BN for compatibility.
    height: BN
    #seq of all the blocks, and another of all the difficulties.
    blocks: seq[Block]
    difficulties: seq[Difficulty]

#Create a new Blockchain.
proc newBlockchain*(genesis: string): Blockchain {.raises: [ValueError, AssertionError].} =
    #Set the current time as the time of creation.
    let creation: BN = getTime()

    #Init the object.
    result = Blockchain(
        height: newBN(),
        blocks: @[],
        difficulties: @[]
    )

    #Append the starting difficulty.
    result.difficulties.add(Difficulty(
        start: creation,
        endTime: creation + newBN(60),
        difficulty: "3333333333333333333333333333333333333333333333333333333333333333".toBN(16)
    ))
    #Append the genesis block. Index 0, creation time, mined to a 0'd public key, with a proof that doesn't matter of "0".
    result.blocks.add(
        newStartBlock(genesis)
    )

#Tests a block for validity.
proc testBlock*(blockchain: Blockchain, newBlock: Block): bool {.raises: [AssertionError, Exception].} =
    #Result is set to true in case if nothing goes wrong.
    result = true

    #If the last hash is off...
    if blockchain.blocks[blockchain.blocks.len-1].getArgon() != newBlock.getLast():
        result = false
        return

    #If the nonce is off...
    if blockchain.height + BNNums.ONE != newBlock.getNonce():
        result = false
        return

    #If the time is before the last block's...
    if newBlock.getTime() < blockchain.blocks[blockchain.blocks.len-1].getTime():
        result = false
        return

    #If the time is ahead of 20 minutes from now...
    if (getTime() + newBN($(20*60))) < newBlock.getTime():
        result = false
        return

    #Generate difficulties so we can test the block against the latest difficulty.
    while blockchain.difficulties[blockchain.difficulties.len-1].endTime < newBlock.getTime():
        blockchain.difficulties.add(calculateNextDifficulty(blockchain.blocks, blockchain.difficulties, (60), 6))

    #If the difficulty wasn't beat...
    if not blockchain.difficulties[blockchain.difficulties.len-1].verifyDifficulty(newBlock):
        result = false
        return

#Adds a block to the blockchain.
proc addBlock*(blockchain: Blockchain, newBlock: Block): bool {.raises: [AssertionError, Exception].} =
    #Test the block.
    if not blockchain.testBlock(newBlock):
        result = false
        return

    #If we're still here, increase the height, append the new block, and return true.
    inc(blockchain.height)
    blockchain.blocks.add(newBlock)
    result = true

#Getters.
proc getHeight*(blockchain: Blockchain): BN {.raises: [].} =
    blockchain.height
proc getBlocks*(blockchain: Blockchain): seq[Block] {.raises: [].} =
    blockchain.blocks
proc getDifficulties*(blockchain: Blockchain): seq[Difficulty] {.raises: [].} =
    blockchain.difficulties
