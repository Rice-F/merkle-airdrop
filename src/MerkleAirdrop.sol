// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20;

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    /**
     * State Variables
     */
    address[] claimers; // 领取者的地址
    bytes32 private immutable i_merkleRoot; // 根节点hash值
    IERC20 private immutable i_airdropToken;
    mapping(address claimer => bool claimed) private s_hasClaimed; // 是否已经领取

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdropToken = airdropToken;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        // 检查是否已经领取
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // 生成哈希值，2次操作防止哈希碰撞
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(account, amount)))
        );
        // 与根节点哈希值比较
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        // 标记已经领取
        s_hasClaimed[account] = true;
        // 发送代币
        emit Claim(account, amount);
        i_airdropToken.safeTransfer(account, amount);
    }

    /**
     * getters
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airdropToken;
    }
}
