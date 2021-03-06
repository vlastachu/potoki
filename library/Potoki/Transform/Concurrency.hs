module Potoki.Transform.Concurrency
(
  bufferize,
  concurrently,
)
where

import Potoki.Prelude hiding (take, takeWhile, filter)
import Potoki.Core.Transform
import qualified Potoki.Fetch as A
import qualified Potoki.Core.Fetch as A
import qualified Control.Concurrent.Chan.Unagi.Bounded as B


{-# INLINE bufferize #-}
bufferize :: Int -> Transform element element
bufferize size =
  Transform $ \ (A.Fetch fetch) -> do
    (inChan, outChan) <- B.newChan size
    forkIO $ fix $ \ loop ->
      join $ fetch
        (B.writeChan inChan Nothing)
        (\ !element -> B.writeChan inChan (Just element) >> loop)
    return $ A.Fetch $ \ nil just -> fmap (maybe nil just) (B.readChan outChan)

{-|
Identity Transform, which ensures that the inputs are fetched synchronously.

Useful for concurrent transforms.
-}
{-# INLINABLE sync #-}
sync :: Transform a a
sync =
  Transform $ \ (A.Fetch fetch) -> do
    activeVar <- newMVar True
    return $ A.Fetch $ \ nil just -> do
      active <- takeMVar activeVar
      if active
        then join $ fetch
          (do
            putMVar activeVar False
            return nil)
          (\ !element -> do
            putMVar activeVar True
            return (just element))
        else do
          putMVar activeVar False
          return nil

{-|
Execute the transform on the specified amount of threads.
The order of the outputs produced is indiscriminate.
-}
{-# INLINABLE concurrently #-}
concurrently :: Int -> Transform input output -> Transform input output
concurrently workersAmount transform =
  sync >>>
  concurrentlyUnsafe workersAmount transform

{-# INLINE concurrentlyUnsafe #-}
concurrentlyUnsafe :: Int -> Transform input output -> Transform input output
concurrentlyUnsafe workersAmount (Transform syncTransformIO) =
  Transform $ \ fetch -> do
    outChan <- newEmptyMVar
    replicateM_ workersAmount $ forkIO $ do
      A.Fetch fetchIO <- syncTransformIO fetch
      fix $ \ loop -> join $ fetchIO
        (putMVar outChan Nothing)
        (\ !result -> putMVar outChan (Just result) >> loop)
    activeWorkersAmountVar <- newMVar workersAmount
    return $ A.Fetch $ \ nil just -> fix $ \ loop -> do
      activeWorkersAmount <- takeMVar activeWorkersAmountVar
      if activeWorkersAmount <= 0
        then return nil
        else do
          fetchResult <- takeMVar outChan
          case fetchResult of
            Just result -> do
              putMVar activeWorkersAmountVar activeWorkersAmount
              return (just result)
            Nothing -> do
              putMVar activeWorkersAmountVar (pred activeWorkersAmount)
              loop
